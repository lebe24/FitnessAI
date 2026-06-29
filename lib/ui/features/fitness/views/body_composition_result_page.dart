import 'dart:io';

import 'package:fitness/data/services/fitness/body_composition_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg     = Color(0xFF0A0C12);
const _kCard   = Color(0xFF111318);
const _kCard2  = Color(0xFF161B26);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kAmber  = Color(0xFFFFAA00);
const _kRed    = Color(0xFFFF4D4D);
const _kBlue   = Color(0xFF4D9EFF);
const _kPurple = Color(0xFFB47EFF);
const _kGreen  = Color(0xFF4DFF9E);
const _kDim    = Color(0x80FFFFFF);

class BodyCompositionResultPage extends StatelessWidget {
  final BodyCompositionResult result;
  final String? imagePath;

  const BodyCompositionResultPage({
    super.key,
    required this.result,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero image sliver ───────────────────────────────────────────────
          _ImageSliver(imagePath: imagePath),

          // ── Overall score + body type ────────────────────────────────────────
          SliverToBoxAdapter(child: _OverallHeader(result: result)),

          // ── Summary ─────────────────────────────────────────────────────────
          _sectionHeader('Summary'),
          SliverToBoxAdapter(child: _SummaryCard(result: result)),

          // ── Composition metrics ──────────────────────────────────────────────
          _sectionHeader('Body Composition'),
          SliverToBoxAdapter(child: _CompositionCard(m: result.composition)),

          // ── Physique scores radar ────────────────────────────────────────────
          _sectionHeader('Physique Scores'),
          SliverToBoxAdapter(child: _PhysiqueScoresCard(s: result.physiqueScores)),

          // ── Muscle map ───────────────────────────────────────────────────────
          _sectionHeader('Muscle Development Map'),
          SliverToBoxAdapter(child: _MuscleMapCard(m: result.muscleMap)),

          // ── Posture ──────────────────────────────────────────────────────────
          _sectionHeader('Posture Analysis'),
          SliverToBoxAdapter(child: _PostureCard(p: result.posture)),

          // ── Symmetry ─────────────────────────────────────────────────────────
          _sectionHeader('Symmetry'),
          SliverToBoxAdapter(child: _SymmetryCard(s: result.symmetry)),

          // ── Fat distribution ─────────────────────────────────────────────────
          _sectionHeader('Fat Distribution'),
          SliverToBoxAdapter(child: _FatDistCard(f: result.fatDistribution)),

          // ── Strengths & improvements ─────────────────────────────────────────
          _sectionHeader('Strengths & Focus Areas'),
          SliverToBoxAdapter(child: _StrengthsCard(result: result)),

          // ── Recommendations ──────────────────────────────────────────────────
          _sectionHeader('Recommendations'),
          SliverToBoxAdapter(child: _RecommendationsCard(r: result.recommendations)),

          // ── Disclaimer ───────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _Disclaimer(text: result.disclaimer)),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  static SliverToBoxAdapter _sectionHeader(String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Text(title, style: GoogleFonts.poppins(
        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
      )),
    ),
  );
}

// ── Hero image ────────────────────────────────────────────────────────────────

class _ImageSliver extends StatelessWidget {
  final String? imagePath;
  const _ImageSliver({this.imagePath});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      backgroundColor: _kBg,
      pinned: false,
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
            imagePath != null
                ? Image.file(File(imagePath!), fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
            DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, _kBg],
                stops: const [0.5, 1.0],
              ),
            )),
            // Badge
            Positioned(
              bottom: 20, left: 20,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kLime.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kLime.withValues(alpha: 0.3)),
                  ),
                  child: Text('BODY COMPOSITION SCAN', style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w800, color: _kLime, letterSpacing: 1,
                  )),
                ),
                const SizedBox(height: 8),
                Text('AI Analysis Report', style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: _kCard2,
    child: Center(child: Icon(Icons.accessibility_new_rounded, size: 64,
        color: _kLime.withValues(alpha: 0.15))),
  );
}

// ── Overall header ────────────────────────────────────────────────────────────

class _OverallHeader extends StatelessWidget {
  final BodyCompositionResult result;
  const _OverallHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    final score = result.physiqueScores.overall;
    final scoreColor = score >= 70 ? _kGreen : score >= 45 ? _kAmber : _kRed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(children: [
        // Circular score
        SizedBox(
          width: 90, height: 90,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 90, height: 90,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$score', style: GoogleFonts.poppins(
                fontSize: 26, fontWeight: FontWeight.w900, color: scoreColor,
              )),
              Text('/100', style: GoogleFonts.inter(fontSize: 10, color: _kDim)),
            ]),
          ]),
        ),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _InfoRow(label: 'Body Type', value: result.bodyType.replaceAll('-', '–').toUpperCase()),
          const SizedBox(height: 6),
          _InfoRow(label: 'Est. Age', value: result.estimatedAgeRange),
          const SizedBox(height: 6),
          _InfoRow(label: 'Gender', value: result.genderPresented),
          const SizedBox(height: 6),
          _InfoRow(label: 'BMR',
              value: result.composition.estimatedBmrKcal != null
                  ? '${result.composition.estimatedBmrKcal} kcal/day'
                  : 'Provide height & weight'),
        ])),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text('$label  ', style: GoogleFonts.inter(fontSize: 11, color: _kDim)),
    Expanded(child: Text(value, style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
        overflow: TextOverflow.ellipsis)),
  ]);
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final BodyCompositionResult result;
  const _SummaryCard({required this.result});

  @override
  Widget build(BuildContext context) => _Card(child: Text(
    result.overallSummary,
    style: GoogleFonts.inter(fontSize: 13, height: 1.7, color: Colors.white.withValues(alpha: 0.85)),
  ));
}

// ── Composition card ──────────────────────────────────────────────────────────

class _CompositionCard extends StatelessWidget {
  final BodyCompositionMetrics m;
  const _CompositionCard({required this.m});

  @override
  Widget build(BuildContext context) {
    final fatColor = m.bodyFatPct < 15 ? _kGreen : m.bodyFatPct < 25 ? _kAmber : _kRed;
    final visceralColor = m.visceralFatRisk == 'low' ? _kGreen
        : m.visceralFatRisk == 'moderate' ? _kAmber : _kRed;
    return _Card(child: Column(children: [
      // Body fat + muscle mass big numbers
      Row(children: [
        Expanded(child: _BigMetric(
          label: 'Body Fat',
          value: '${m.bodyFatPct.toStringAsFixed(1)}%',
          sub: m.bodyFatCategory,
          color: fatColor,
        )),
        Container(width: 1, height: 60, color: Colors.white.withValues(alpha: 0.07)),
        Expanded(child: _BigMetric(
          label: 'Muscle Mass',
          value: '${m.muscleMassPct.toStringAsFixed(1)}%',
          sub: m.leanMassNote,
          color: _kBlue,
        )),
      ]),
      const SizedBox(height: 16),
      Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
      const SizedBox(height: 14),
      // Visceral fat risk
      Row(children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: visceralColor, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('Visceral Fat Risk', style: GoogleFonts.inter(fontSize: 12, color: _kDim)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: visceralColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: visceralColor.withValues(alpha: 0.3)),
          ),
          child: Text(m.visceralFatRisk.toUpperCase(), style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w800, color: visceralColor,
          )),
        ),
      ]),
    ]));
  }
}

class _BigMetric extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  const _BigMetric({required this.label, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(children: [
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: _kDim)),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w900, color: color,
      )),
      Text(sub, style: GoogleFonts.inter(fontSize: 10, color: color.withValues(alpha: 0.7)),
          textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ── Physique scores card ──────────────────────────────────────────────────────

class _PhysiqueScoresCard extends StatelessWidget {
  final PhysiqueScores s;
  const _PhysiqueScoresCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final scores = [
      (label: 'Overall',    value: s.overall,           color: _kLime),
      (label: 'Aesthetics', value: s.aesthetics,        color: _kPurple),
      (label: 'Symmetry',   value: s.symmetry,          color: _kBlue),
      (label: 'Muscle Dev', value: s.muscleDevelopment, color: _kAmber),
      (label: 'Conditioning', value: s.conditioning,    color: _kGreen),
      (label: 'Posture',    value: s.posture,            color: _kRed.withValues(alpha: 0.9)),
    ];

    return _Card(child: Column(
      children: scores.map((e) {
        final pct = e.value / 100;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(e.label, style: GoogleFonts.inter(fontSize: 12, color: _kDim)),
              const Spacer(),
              Text('${e.value}', style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w800, color: e.color)),
              Text('/100', style: GoogleFonts.inter(fontSize: 10, color: _kDim)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(e.color),
              ),
            ),
          ]),
        );
      }).toList(),
    ));
  }
}

// ── Muscle map card ───────────────────────────────────────────────────────────

class _MuscleMapCard extends StatelessWidget {
  final MuscleMap m;
  const _MuscleMapCard({required this.m});

  @override
  Widget build(BuildContext context) {
    final upper = m.upperBody;
    final core  = m.core;
    final lower = m.lowerBody;

    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _MuscleGroupHeader('Upper Body'),
      _MuscleRow('Chest',     upper.chest),
      _MuscleRow('Back',      upper.back),
      _MuscleRow('Shoulders', upper.shoulders),
      _MuscleRow('Biceps',    upper.biceps),
      _MuscleRow('Triceps',   upper.triceps),
      _MuscleRow('Forearms',  upper.forearms),
      const SizedBox(height: 4),
      _MuscleGroupHeader('Core'),
      _MuscleRow('Abs',        core.abs),
      _MuscleRow('Obliques',   core.obliques),
      _MuscleRow('Lower Back', core.lowerBack),
      const SizedBox(height: 4),
      _MuscleGroupHeader('Lower Body'),
      _MuscleRow('Quads',      lower.quads),
      _MuscleRow('Hamstrings', lower.hamstrings),
      _MuscleRow('Glutes',     lower.glutes),
      _MuscleRow('Calves',     lower.calves),
    ]));
  }
}

class _MuscleGroupHeader extends StatelessWidget {
  final String label;
  const _MuscleGroupHeader(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(label, style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: Colors.white.withValues(alpha: 0.4), letterSpacing: 0.5,
    )),
  );
}

class _MuscleRow extends StatelessWidget {
  final String label;
  final MuscleGroupScore s;
  const _MuscleRow(this.label, this.s);

  Color get _scoreColor {
    if (s.score >= 8) return _kGreen;
    if (s.score >= 6) return _kLime;
    if (s.score >= 4) return _kAmber;
    return _kRed;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        SizedBox(
          width: 100,
          child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: _kDim)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: s.score / 10,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('${s.score}/10', style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700, color: _scoreColor)),
      ]),
      if (s.notes.isNotEmpty) ...[
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 100),
          child: Text(s.notes, style: GoogleFonts.inter(
              fontSize: 10, color: Colors.white.withValues(alpha: 0.35),
              fontStyle: FontStyle.italic)),
        ),
      ],
    ]),
  );
}

// ── Posture card ──────────────────────────────────────────────────────────────

class _PostureCard extends StatelessWidget {
  final PostureAnalysis p;
  const _PostureCard({required this.p});

  @override
  Widget build(BuildContext context) => _Card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(p.overall, style: GoogleFonts.inter(
          fontSize: 13, height: 1.6, color: Colors.white.withValues(alpha: 0.85))),
      const SizedBox(height: 14),
      _PostureLine('Spine', p.spineAlignment),
      _PostureLine('Shoulders', p.shoulderBalance),
      _PostureLine('Hips', p.hipAlignment),
      if (p.identifiedIssues.isNotEmpty) ...[
        const SizedBox(height: 14),
        _BulletSection(title: 'Issues Found', items: p.identifiedIssues, color: _kAmber),
      ],
      if (p.correctiveRecommendations.isNotEmpty) ...[
        const SizedBox(height: 10),
        _BulletSection(title: 'Corrective Exercises', items: p.correctiveRecommendations, color: _kGreen),
      ],
    ],
  ));
}

class _PostureLine extends StatelessWidget {
  final String label, value;
  const _PostureLine(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 80, child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: _kDim))),
      Expanded(child: Text(value, style: GoogleFonts.inter(
          fontSize: 12, height: 1.5, color: Colors.white.withValues(alpha: 0.8)))),
    ]),
  );
}

// ── Symmetry card ─────────────────────────────────────────────────────────────

class _SymmetryCard extends StatelessWidget {
  final SymmetryAnalysis s;
  const _SymmetryCard({required this.s});

  @override
  Widget build(BuildContext context) => _Card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PostureLine('Bilateral',   s.bilateralBalance),
      _PostureLine('Upper/Lower', s.upperLowerBalance),
      _PostureLine('Front/Back',  s.anteriorPosteriorBalance),
      if (s.notableImbalances.isNotEmpty) ...[
        const SizedBox(height: 10),
        _BulletSection(title: 'Notable Imbalances', items: s.notableImbalances, color: _kAmber),
      ],
    ],
  ));
}

// ── Fat distribution card ─────────────────────────────────────────────────────

class _FatDistCard extends StatelessWidget {
  final FatDistribution f;
  const _FatDistCard({required this.f});

  @override
  Widget build(BuildContext context) => _Card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        _PatternBadge(f.pattern),
        const SizedBox(width: 10),
        Expanded(child: Text(f.visceralRisk, style: GoogleFonts.inter(
            fontSize: 12, height: 1.5, color: Colors.white.withValues(alpha: 0.8)))),
      ]),
      const SizedBox(height: 12),
      Text('Primary Storage Areas', style: GoogleFonts.inter(
          fontSize: 11, color: _kDim, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6, runSpacing: 6,
        children: f.primaryStorageAreas.map((a) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder),
          ),
          child: Text(a, style: GoogleFonts.inter(fontSize: 11, color: _kDim)),
        )).toList(),
      ),
    ],
  ));
}

class _PatternBadge extends StatelessWidget {
  final String pattern;
  const _PatternBadge(this.pattern);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: _kBlue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kBlue.withValues(alpha: 0.3)),
    ),
    child: Text(pattern.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w800, color: _kBlue, letterSpacing: 0.5,
    )),
  );
}

// ── Strengths card ────────────────────────────────────────────────────────────

class _StrengthsCard extends StatelessWidget {
  final BodyCompositionResult result;
  const _StrengthsCard({required this.result});

  @override
  Widget build(BuildContext context) => _Card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (result.strengths.isNotEmpty)
        _BulletSection(title: 'Strengths', items: result.strengths, color: _kGreen),
      if (result.strengths.isNotEmpty && result.improvementAreas.isNotEmpty)
        const SizedBox(height: 14),
      if (result.improvementAreas.isNotEmpty)
        _BulletSection(title: 'Focus Areas', items: result.improvementAreas, color: _kAmber),
    ],
  ));
}

// ── Recommendations card ──────────────────────────────────────────────────────

class _RecommendationsCard extends StatelessWidget {
  final BodyCompositionRecommendations r;
  const _RecommendationsCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final rows = [
      (icon: Icons.flag_rounded,          label: 'Priority',      value: r.priorityFocus),
      (icon: Icons.fitness_center_rounded, label: 'Training',     value: r.recommendedTrainingStyle),
      (icon: Icons.directions_run_rounded, label: 'Cardio',       value: r.cardioRecommendation),
      (icon: Icons.restaurant_rounded,     label: 'Nutrition',    value: r.nutritionStrategy),
      (icon: Icons.calendar_today_rounded, label: 'Frequency',    value: r.weeklyTrainingDays),
      (icon: Icons.timer_outlined,         label: 'Timeline',     value: r.estimatedGoalTimeline),
    ];

    return _Card(child: Column(
      children: rows.asMap().entries.map((e) {
        final r = e.value;
        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(r.icon, size: 16, color: _kLime),
              const SizedBox(width: 10),
              SizedBox(width: 72, child: Text(r.label, style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _kDim))),
              Expanded(child: Text(r.value, style: GoogleFonts.inter(
                  fontSize: 13, height: 1.5, color: Colors.white.withValues(alpha: 0.85)))),
            ]),
          ),
          if (e.key < rows.length - 1)
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
        ]);
      }).toList(),
    ));
  }
}

// ── Disclaimer ────────────────────────────────────────────────────────────────

class _Disclaimer extends StatelessWidget {
  final String text;
  const _Disclaimer({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, size: 14, color: _kDim),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.inter(
            fontSize: 11, height: 1.6, color: Colors.white.withValues(alpha: 0.35)))),
      ]),
    ),
  );
}

// ── Shared: bullet section ────────────────────────────────────────────────────

class _BulletSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  const _BulletSection({required this.title, required this.items, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.8), letterSpacing: 0.4)),
      const SizedBox(height: 6),
      ...items.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 5, right: 8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          Expanded(child: Text(s, style: GoogleFonts.inter(
              fontSize: 13, height: 1.5, color: Colors.white.withValues(alpha: 0.8)))),
        ]),
      )),
    ],
  );
}

// ── Shared: card wrapper ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: child,
    ),
  );
}
