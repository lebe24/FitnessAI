import 'dart:io';

import 'package:fitness/data/models/nutrition/stored_nutrition_analysis_model.dart';
import 'package:fitness/domain/models/nutrition_analysis.dart';
import 'package:fitness/ui/features/nutrition/view_models/nutrition_view_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg     = Color(0xFF0A0C12);
const _kCard   = Color(0xFF111318);
const _kCard2  = Color(0xFF161B26);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kDim    = Color(0x80FFFFFF);
const _kAmber  = Color(0xFFFFAA00);
const _kRed    = Color(0xFFFF4D4D);
const _kBlue   = Color(0xFF4D9EFF);
const _kPurple = Color(0xFFB47EFF);
const _kGreen  = Color(0xFF4DFF9E);

class AnalysisOutputPage extends StatefulWidget {
  const AnalysisOutputPage({
    super.key,
    this.analysis,
    this.imagePath,
    this.heroTag,
    this.analysisType = 'full_analysis',
  });

  final NutritionAnalysisEntity? analysis;
  final String? imagePath;
  final String? heroTag;
  final String analysisType;

  @override
  State<AnalysisOutputPage> createState() => _AnalysisOutputPageState();
}

class _AnalysisOutputPageState extends State<AnalysisOutputPage> {
  bool _isSaved = false;
  bool _saving = false;
  NutritionViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm == null) {
      _vm = context.read<NutritionViewModel>();
      _vm!.addListener(_onVmChanged);
    }
  }

  void _onVmChanged() {
    if (!mounted) return;
    final vm = _vm!;
    if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(vm.error!, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      vm.clearError();
    }
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    super.dispose();
  }

  Future<void> _saveMeal() async {
    if (widget.analysis == null || _isSaved) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final stored = StoredNutritionAnalysisModel(
      id: const Uuid().v4(),
      analysis: widget.analysis!,
      imagePath: widget.imagePath,
      createdAt: now,
      updatedAt: now,
    );
    await _vm!.saveAnalysis(stored);
    if (mounted) setState(() { _isSaved = true; _saving = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Meal saved!', style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
        backgroundColor: const Color(0xFF1A2A00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  bool get _isFullAnalysis => widget.analysisType == 'full_analysis';

  @override
  Widget build(BuildContext context) {
    if (widget.analysis == null) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Center(child: Text(
          'No analysis data',
          style: GoogleFonts.poppins(color: Colors.white54),
        )),
      );
    }

    final a = widget.analysis!;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _FoodImageSliver(imagePath: widget.imagePath, heroTag: widget.heroTag),

              // ── Type badge + dish name ──────────────────────────────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    _TypeBadge(isFullAnalysis: _isFullAnalysis),
                    const Spacer(),
                    _HealthScore(score: a.healthinessScore, rating: a.overallRating),
                  ]),
                  const SizedBox(height: 14),
                  Text(a.dishName, style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15,
                  )),
                ]),
              )),

              // ── Calories hero row ────────────────────────────────────────────
              SliverToBoxAdapter(child: _CaloriesHero(a: a)),

              if (_isFullAnalysis)
                ..._fullAnalysisSections(a)
              else
                ..._nutrientBreakdownSections(a),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),

          // ── Save button ───────────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _SaveBar(
              isSaved: _isSaved,
              saving: _saving,
              onSave: _saveMeal,
            ),
          ),
        ],
      ),
    );
  }

  // ── Full Analysis sections ──────────────────────────────────────────────────

  List<Widget> _fullAnalysisSections(NutritionAnalysisEntity a) => [
    _sectionHeader('Macronutrients'),
    SliverToBoxAdapter(child: _MacroGrid(a: a)),

    _sectionHeader('Macro Distribution'),
    SliverToBoxAdapter(child: _MacroPieChart(a: a)),

    _sectionHeader('Ingredients'),
    SliverToBoxAdapter(child: _IngredientsCard(items: a.identifiedIngredients)),

    _sectionHeader('Micronutrients'),
    SliverToBoxAdapter(child: _MicronutrientsCard(micro: a.micronutrientsEstimate)),

    _sectionHeader('Dietary Info'),
    SliverToBoxAdapter(child: _DietaryCard(safety: a.dietarySafetyConstraints)),

    if (a.workoutContext.postWorkoutRecommended || a.workoutContext.why.isNotEmpty) ...[
      _sectionHeader('Workout Context'),
      SliverToBoxAdapter(child: _WorkoutContextCard(ctx: a.workoutContext)),
    ],

    if (a.nutrientHighlights.positive.isNotEmpty ||
        a.nutrientHighlights.moderate.isNotEmpty) ...[
      _sectionHeader('Highlights'),
      SliverToBoxAdapter(child: _HighlightsCard(h: a.nutrientHighlights)),
    ],

    if (a.notes.isNotEmpty) ...[
      _sectionHeader('Notes'),
      SliverToBoxAdapter(child: _NotesCard(notes: a.notes)),
    ],
  ];

  // ── Nutrient Breakdown sections ─────────────────────────────────────────────

  List<Widget> _nutrientBreakdownSections(NutritionAnalysisEntity a) => [
    _sectionHeader('Macronutrient Breakdown'),
    SliverToBoxAdapter(child: _DetailedMacroCard(a: a)),

    _sectionHeader('Macro Distribution'),
    SliverToBoxAdapter(child: _MacroPieChart(a: a)),

    if (a.macroEstimates.fats.breakdown != null) ...[
      _sectionHeader('Fat Breakdown'),
      SliverToBoxAdapter(child: _FatBreakdownCard(fats: a.macroEstimates.fats)),
    ],

    _sectionHeader('Micronutrients'),
    SliverToBoxAdapter(child: _MicronutrientsCard(micro: a.micronutrientsEstimate)),

    if (a.notes.isNotEmpty) ...[
      _sectionHeader('Notes'),
      SliverToBoxAdapter(child: _NotesCard(notes: a.notes)),
    ],
  ];

  SliverToBoxAdapter _sectionHeader(String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Text(title, style: GoogleFonts.poppins(
        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
      )),
    ),
  );
}

// ── Food image sliver ─────────────────────────────────────────────────────────

class _FoodImageSliver extends StatelessWidget {
  final String? imagePath;
  final String? heroTag;
  const _FoodImageSliver({this.imagePath, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final Widget img = imagePath != null
        ? Image.file(File(imagePath!), fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder())
        : _placeholder();

    return SliverAppBar(
      expandedHeight: 280,
      backgroundColor: _kBg,
      pinned: false,
      floating: false,
      stretch: true,
      leading: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            heroTag != null
                ? Hero(tag: heroTag!, child: img)
                : img,
            // gradient fade into page bg
            const DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, _kBg],
                stops: [0.55, 1.0],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: _kCard2,
    child: Center(child: Icon(Icons.restaurant_menu_rounded, size: 48,
        color: _kLime.withValues(alpha: 0.2))),
  );
}

// ── Type badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final bool isFullAnalysis;
  const _TypeBadge({required this.isFullAnalysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kLime.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kLime.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isFullAnalysis ? Icons.analytics_rounded : Icons.pie_chart_rounded,
            size: 11, color: _kLime),
        const SizedBox(width: 5),
        Text(
          isFullAnalysis ? 'FULL ANALYSIS' : 'NUTRIENT BREAKDOWN',
          style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w800, color: _kLime, letterSpacing: 0.8,
          ),
        ),
      ]),
    );
  }
}

// ── Health score ──────────────────────────────────────────────────────────────

class _HealthScore extends StatelessWidget {
  final double score;
  final String rating;
  const _HealthScore({required this.score, required this.rating});

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).toInt();
    final color = score >= 0.7 ? _kGreen : score >= 0.4 ? _kAmber : _kRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text('$pct%', style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w800, color: color,
        )),
        Text(rating, style: GoogleFonts.inter(fontSize: 9, color: color.withValues(alpha: 0.8))),
      ]),
    );
  }
}

// ── Calories hero ─────────────────────────────────────────────────────────────

class _CaloriesHero extends StatelessWidget {
  final NutritionAnalysisEntity a;
  const _CaloriesHero({required this.a});

  @override
  Widget build(BuildContext context) {
    final m = a.estimatedNutrition.macros;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kCard, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          // Calories pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kLime.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Text('${a.estimatedNutrition.caloriesKcal}', style: GoogleFonts.poppins(
                fontSize: 28, fontWeight: FontWeight.w900, color: _kLime,
              )),
              Text('kcal', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _kLime)),
            ]),
          ),
          const SizedBox(width: 20),
          Expanded(child: Column(children: [
            _MacroMini(label: 'Protein', value: '${m.proteinG.toInt()}g', color: _kBlue),
            const SizedBox(height: 8),
            _MacroMini(label: 'Carbs', value: '${m.carbsG.toInt()}g', color: _kGreen),
            const SizedBox(height: 8),
            _MacroMini(label: 'Fat', value: '${m.fatG.toInt()}g', color: _kPurple),
            const SizedBox(height: 8),
            _MacroMini(label: 'Fiber', value: '${m.fiberG.toInt()}g', color: _kAmber),
          ])),
        ]),
      ),
    );
  }
}

class _MacroMini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroMini({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Text(label, style: GoogleFonts.inter(fontSize: 12, color: _kDim)),
    const Spacer(),
    Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
  ]);
}

// ── Macro grid (full analysis) ────────────────────────────────────────────────

class _MacroGrid extends StatelessWidget {
  final NutritionAnalysisEntity a;
  const _MacroGrid({required this.a});

  @override
  Widget build(BuildContext context) {
    final p = a.macroEstimates.protein;
    final c = a.macroEstimates.carbohydrates;
    final f = a.macroEstimates.fats;
    final fi = a.macroEstimates.fiber;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        Row(children: [
          Expanded(child: _MacroCell(label: 'Protein', grams: p.grams, pct: p.percentage,
              kcal: p.calories, color: _kBlue, note: p.quality)),
          const SizedBox(width: 10),
          Expanded(child: _MacroCell(label: 'Carbs', grams: c.grams, pct: c.percentage,
              kcal: c.calories, color: _kGreen, note: c.type)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _MacroCell(label: 'Fat', grams: f.grams, pct: f.percentage,
              kcal: f.calories, color: _kPurple)),
          const SizedBox(width: 10),
          Expanded(child: _MacroCell(label: 'Fiber', grams: fi.grams, pct: fi.percentage,
              kcal: null, color: _kAmber)),
        ]),
      ]),
    );
  }
}

class _MacroCell extends StatelessWidget {
  final String label;
  final double grams;
  final double pct;
  final double? kcal;
  final Color color;
  final String? note;
  const _MacroCell({required this.label, required this.grams, required this.pct,
      required this.kcal, required this.color, this.note});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.9))),
      ]),
      const SizedBox(height: 10),
      Text('${grams.toInt()}g', style: GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
      )),
      Row(children: [
        Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.inter(fontSize: 11, color: _kDim)),
        if (kcal != null) ...[
          const SizedBox(width: 6),
          Text('·', style: GoogleFonts.inter(color: _kDim)),
          const SizedBox(width: 6),
          Text('${kcal!.toInt()} kcal', style: GoogleFonts.inter(fontSize: 11, color: _kDim)),
        ],
      ]),
      if (note != null && note!.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(note!, style: GoogleFonts.inter(fontSize: 10,
            color: color.withValues(alpha: 0.7), fontStyle: FontStyle.italic)),
      ],
    ]),
  );
}

// ── Macro pie chart ───────────────────────────────────────────────────────────

class _MacroPieChart extends StatefulWidget {
  final NutritionAnalysisEntity a;
  const _MacroPieChart({required this.a});
  @override
  State<_MacroPieChart> createState() => _MacroPieChartState();
}

class _MacroPieChartState extends State<_MacroPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final p = widget.a.macroEstimates.protein.percentage;
    final c = widget.a.macroEstimates.carbohydrates.percentage;
    final f = widget.a.macroEstimates.fats.percentage;
    final fi = widget.a.macroEstimates.fiber.percentage;

    final sections = [
      (pct: p, color: _kBlue, label: 'Protein'),
      (pct: c, color: _kGreen, label: 'Carbs'),
      (pct: f, color: _kPurple, label: 'Fat'),
      (pct: fi, color: _kAmber, label: 'Fiber'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kCard, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          SizedBox(
            width: 160, height: 160,
            child: PieChart(PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (e, r) => setState(() {
                  _touched = (e.isInterestedForInteractions && r?.touchedSection != null)
                      ? r!.touchedSection!.touchedSectionIndex
                      : -1;
                }),
              ),
              sectionsSpace: 2,
              centerSpaceRadius: 42,
              sections: sections.asMap().entries.map((e) {
                final isTouched = e.key == _touched;
                return PieChartSectionData(
                  value: e.value.pct,
                  color: e.value.color,
                  radius: isTouched ? 52 : 44,
                  showTitle: isTouched,
                  title: '${e.value.pct.toStringAsFixed(1)}%',
                  titleStyle: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black,
                  ),
                );
              }).toList(),
            )),
          ),
          const SizedBox(width: 20),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sections.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(s.label, style: GoogleFonts.inter(fontSize: 13, color: _kDim))),
                Text('${s.pct.toStringAsFixed(1)}%', style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            )).toList(),
          )),
        ]),
      ),
    );
  }
}

// ── Detailed macro card (nutrient breakdown) ──────────────────────────────────

class _DetailedMacroCard extends StatelessWidget {
  final NutritionAnalysisEntity a;
  const _DetailedMacroCard({required this.a});

  @override
  Widget build(BuildContext context) {
    final items = [
      (label: 'Protein', grams: a.macroEstimates.protein.grams,
          pct: a.macroEstimates.protein.percentage, kcal: a.macroEstimates.protein.calories, color: _kBlue),
      (label: 'Carbohydrates', grams: a.macroEstimates.carbohydrates.grams,
          pct: a.macroEstimates.carbohydrates.percentage, kcal: a.macroEstimates.carbohydrates.calories, color: _kGreen),
      (label: 'Fat', grams: a.macroEstimates.fats.grams,
          pct: a.macroEstimates.fats.percentage, kcal: a.macroEstimates.fats.calories, color: _kPurple),
      (label: 'Fiber', grams: a.macroEstimates.fiber.grams,
          pct: a.macroEstimates.fiber.percentage, kcal: 0.0, color: _kAmber),
    ];
    final total = a.estimatedNutrition.caloriesKcal.toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: items.asMap().entries.map((e) {
            final item = e.value;
            final barWidth = item.pct / 100;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(item.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    const Spacer(),
                    Text('${item.grams.toInt()}g', style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(width: 10),
                    Container(
                      width: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: item.color.withValues(alpha: 0.3)),
                      ),
                      child: Text('${item.pct.toStringAsFixed(1)}%', textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: item.color)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: barWidth.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(item.color),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (item.kcal > 0)
                    Text('${item.kcal.toInt()} kcal  ·  ${total > 0 ? ((item.kcal / total) * 100).toStringAsFixed(0) : 0}% of total',
                        style: GoogleFonts.inter(fontSize: 11, color: _kDim)),
                ]),
              ),
              if (e.key < items.length - 1)
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ── Fat breakdown card ────────────────────────────────────────────────────────

class _FatBreakdownCard extends StatelessWidget {
  final Fats fats;
  const _FatBreakdownCard({required this.fats});

  @override
  Widget build(BuildContext context) {
    final b = fats.breakdown!;
    final total = fats.grams;
    final rows = [
      (label: 'Saturated', g: b.saturatedG, color: _kRed),
      (label: 'Monounsaturated', g: b.monounsaturatedG, color: _kAmber),
      (label: 'Polyunsaturated', g: b.polyunsaturatedG, color: _kGreen),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kCard, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: rows.map((r) {
            final pct = total > 0 ? (r.g / total) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: r.color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.label, style: GoogleFonts.inter(fontSize: 13, color: _kDim))),
                  Text('${r.g.toStringAsFixed(1)}g', style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(r.color),
                  ),
                ),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Ingredients card ──────────────────────────────────────────────────────────

class _IngredientsCard extends StatelessWidget {
  final List<String> items;
  const _IngredientsCard({required this.items});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: items.map((i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _kLime.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kLime.withValues(alpha: 0.2)),
          ),
          child: Text(i, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _kLime)),
        )).toList(),
      ),
    ),
  );
}

// ── Micronutrients card ───────────────────────────────────────────────────────

class _MicronutrientsCard extends StatelessWidget {
  final MicronutrientsEstimate micro;
  const _MicronutrientsCard({required this.micro});

  @override
  Widget build(BuildContext context) {
    final v = micro.vitamins;
    final m = micro.minerals;

    final vitamins = <(String, double?)>[
      ('Vitamin A', v.vitaminAMcg),
      ('Vitamin C', v.vitaminCMg),
      ('Vitamin D', v.vitaminDIu),
      ('Vitamin E', v.vitaminEMg),
      ('Vitamin K', v.vitaminKMcg),
      ('Thiamine', v.thiamineMg),
      ('Riboflavin', v.riboflavinMg),
      ('Niacin', v.niacinMg),
      ('Vitamin B6', v.vitaminB6Mg),
      ('Folate', v.folateMcg),
      ('Vitamin B12', v.vitaminB12Mcg),
    ].where((e) => e.$2 != null && e.$2! > 0).toList();

    final minerals = <(String, double?)>[
      ('Calcium', m.calciumMg),
      ('Iron', m.ironMg),
      ('Magnesium', m.magnesiumMg),
      ('Phosphorus', m.phosphorusMg),
      ('Potassium', m.potassiumMg),
      ('Sodium', m.sodiumMg),
      ('Zinc', m.zincMg),
      ('Copper', m.copperMg),
      ('Manganese', m.manganeseMg),
      ('Selenium', m.seleniumMcg),
    ].where((e) => e.$2 != null && e.$2! > 0).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (vitamins.isNotEmpty) ...[
            _microHeader('Vitamins', Icons.science_rounded),
            ...vitamins.map((e) => _MicroRow(label: e.$1, value: e.$2!)),
          ],
          if (vitamins.isNotEmpty && minerals.isNotEmpty)
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          if (minerals.isNotEmpty) ...[
            _microHeader('Minerals', Icons.diamond_rounded),
            ...minerals.map((e) => _MicroRow(label: e.$1, value: e.$2!)),
          ],
          if (micro.antioxidants.isNotEmpty) ...[
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            _microHeader('Antioxidants', Icons.local_florist_rounded),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: micro.antioxidants.map((a) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
                  ),
                  child: Text(a, style: GoogleFonts.inter(fontSize: 11, color: _kGreen)),
                )).toList(),
              ),
            ),
          ],
          if (vitamins.isEmpty && minerals.isEmpty && micro.antioxidants.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No micronutrient data available',
                  style: GoogleFonts.inter(fontSize: 13, color: _kDim)),
            ),
        ]),
      ),
    );
  }

  Widget _microHeader(String label, IconData icon) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
    child: Row(children: [
      Icon(icon, size: 14, color: _kDim),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.4), letterSpacing: 0.5)),
    ]),
  );
}

class _MicroRow extends StatelessWidget {
  final String label;
  final double value;
  const _MicroRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
    child: Row(children: [
      Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: _kDim))),
      Text('${value % 1 == 0 ? value.toInt() : value.toStringAsFixed(1)}',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
    ]),
  );
}

// ── Dietary card ──────────────────────────────────────────────────────────────

class _DietaryCard extends StatelessWidget {
  final DietarySafetyConstraints safety;
  const _DietaryCard({required this.safety});

  @override
  Widget build(BuildContext context) {
    final dr = safety.dietaryRestrictions;
    final tags = <(String, bool)>[
      ('Gluten Free', dr.glutenFree),
      ('Vegan', dr.vegan),
      ('Vegetarian', dr.vegetarian),
      ('Halal', dr.halal),
      ('Kosher', dr.kosher),
      ('Dairy Free', dr.dairyFree),
      ('Nut Free', dr.nutFree),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kCard, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Dietary restriction tags
          Wrap(
            spacing: 8, runSpacing: 8,
            children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: t.$2
                    ? _kGreen.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: t.$2 ? _kGreen.withValues(alpha: 0.3) : _kBorder,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(t.$2 ? Icons.check_rounded : Icons.close_rounded,
                    size: 11, color: t.$2 ? _kGreen : Colors.white24),
                const SizedBox(width: 5),
                Text(t.$1, style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: t.$2 ? _kGreen : Colors.white30,
                )),
              ]),
            )).toList(),
          ),

          // Allergens
          if (safety.allergens.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 14),
            Row(children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: _kAmber),
              const SizedBox(width: 6),
              Text('Allergens', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: _kAmber, letterSpacing: 0.4)),
            ]),
            const SizedBox(height: 10),
            ...safety.allergens.map((al) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _kRed.withValues(alpha: 0.3)),
                  ),
                  child: Text(al.severity.toUpperCase(), style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w800, color: _kRed,
                  )),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text('${al.name} — from ${al.source}',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)))),
              ]),
            )),
          ],

          // Safety concerns
          if (safety.safetyConcerns.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 14),
            ...safety.safetyConcerns.map((sc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, size: 14,
                    color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(width: 8),
                Expanded(child: Text(sc.message,
                    style: GoogleFonts.inter(fontSize: 12, height: 1.5, color: _kDim))),
              ]),
            )),
          ],
        ]),
      ),
    );
  }
}

// ── Workout context card ──────────────────────────────────────────────────────

class _WorkoutContextCard extends StatelessWidget {
  final WorkoutContext ctx;
  const _WorkoutContextCard({required this.ctx});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ctx.postWorkoutRecommended
            ? _kGreen.withValues(alpha: 0.06)
            : _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ctx.postWorkoutRecommended
              ? _kGreen.withValues(alpha: 0.3)
              : _kBorder,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ctx.postWorkoutRecommended
                  ? _kGreen.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.fitness_center_rounded, size: 16,
                color: ctx.postWorkoutRecommended ? _kGreen : _kDim),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ctx.postWorkoutRecommended
                    ? 'Great post-workout meal'
                    : 'Post-workout neutral',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: ctx.postWorkoutRecommended ? _kGreen : Colors.white)),
            if (ctx.bestTimingHoursAfterWorkout.isNotEmpty)
              Text('Best ${ctx.bestTimingHoursAfterWorkout} hrs after workout',
                  style: GoogleFonts.inter(fontSize: 11, color: _kDim)),
          ])),
        ]),
        if (ctx.why.isNotEmpty) ...[
          const SizedBox(height: 14),
          ...ctx.why.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 5, right: 8),
                  decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle)),
              Expanded(child: Text(w, style: GoogleFonts.inter(fontSize: 13, height: 1.5,
                  color: Colors.white.withValues(alpha: 0.8)))),
            ]),
          )),
        ],
        if (ctx.ifNoWorkout.suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
          const SizedBox(height: 12),
          Text('If no workout today:', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, color: _kDim, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          ...ctx.ifNoWorkout.suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('· $s', style: GoogleFonts.inter(
                fontSize: 12, height: 1.5, color: Colors.white.withValues(alpha: 0.55))),
          )),
        ],
      ]),
    ),
  );
}

// ── Highlights card ───────────────────────────────────────────────────────────

class _HighlightsCard extends StatelessWidget {
  final NutrientHighlights h;
  const _HighlightsCard({required this.h});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (h.positive.isNotEmpty) ...[
          _hlHeader('Positives', _kGreen),
          ...h.positive.map((s) => _HlRow(text: s, color: _kGreen, icon: Icons.check_circle_rounded)),
        ],
        if (h.moderate.isNotEmpty) ...[
          if (h.positive.isNotEmpty) const SizedBox(height: 8),
          _hlHeader('Moderate', _kAmber),
          ...h.moderate.map((s) => _HlRow(text: s, color: _kAmber, icon: Icons.info_rounded)),
        ],
        if (h.allergens.isNotEmpty) ...[
          if (h.positive.isNotEmpty || h.moderate.isNotEmpty) const SizedBox(height: 8),
          _hlHeader('Allergen Notes', _kRed),
          ...h.allergens.map((s) => _HlRow(text: s, color: _kRed, icon: Icons.warning_rounded)),
        ],
      ]),
    ),
  );

  Widget _hlHeader(String label, Color c) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w700, color: c.withValues(alpha: 0.7), letterSpacing: 0.4)),
  );
}

class _HlRow extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const _HlRow({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: GoogleFonts.inter(
          fontSize: 13, height: 1.5, color: Colors.white.withValues(alpha: 0.8)))),
    ]),
  );
}

// ── Notes card ────────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  final List<String> notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: notes.map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 6, right: 10),
                decoration: const BoxDecoration(color: _kLime, shape: BoxShape.circle)),
            Expanded(child: Text(n, style: GoogleFonts.inter(
                fontSize: 13, height: 1.6, color: Colors.white.withValues(alpha: 0.75)))),
          ]),
        )).toList(),
      ),
    ),
  );
}

// ── Save bar ──────────────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  final bool isSaved;
  final bool saving;
  final VoidCallback onSave;
  const _SaveBar({required this.isSaved, required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomPad),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: GestureDetector(
        onTap: (isSaved || saving) ? null : onSave,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSaved
                ? _kGreen.withValues(alpha: 0.1)
                : saving
                    ? Colors.white.withValues(alpha: 0.05)
                    : _kLime,
            borderRadius: BorderRadius.circular(16),
            border: isSaved
                ? Border.all(color: _kGreen.withValues(alpha: 0.35))
                : null,
            boxShadow: (!isSaved && !saving)
                ? [BoxShadow(color: _kLime.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 5))]
                : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (saving)
              const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))
            else
              Icon(
                isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
                size: 18,
                color: isSaved ? _kGreen : Colors.black,
              ),
            const SizedBox(width: 8),
            Text(
              isSaved ? 'Meal Saved' : saving ? 'Saving…' : 'Save Meal',
              style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: isSaved ? _kGreen : saving ? Colors.white38 : Colors.black,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
