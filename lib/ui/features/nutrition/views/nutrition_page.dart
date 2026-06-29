import 'dart:io';

import 'package:fitness/ui/features/nutrition/view_models/nutrition_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

enum AnalysisType { fullAnalysis, nutrientBreakdown }

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg     = Color(0xFF0A0C12);
const _kCard   = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kDim    = Color(0x80FFFFFF);

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key, this.imagePath});
  final String? imagePath;

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  AnalysisType? _selectedType;
  static const String _heroTag = 'food_image_hero';
  late final NutritionViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<NutritionViewModel>();
    _vm.addListener(_onVmChanged);
  }

  void _onVmChanged() {
    if (!mounted) return;
    final vm = _vm;
    if (vm.analysis != null && !vm.isLoading && vm.error == null) {
      context.push('/nutrition-analysis', extra: {
        'analysis': vm.analysis,
        'imagePath': widget.imagePath,
        'heroTag': _heroTag,
        'analysisType': _selectedType == AnalysisType.fullAnalysis
            ? 'full_analysis'
            : 'nutrient_breakdown',
      });
    } else if (vm.error != null) {
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
    _vm.removeListener(_onVmChanged);
    super.dispose();
  }

  void _analyse(NutritionViewModel vm) {
    if (widget.imagePath == null || _selectedType == null) return;
    vm.analyzeFood(
      image: File(widget.imagePath!),
      extraInfo: _selectedType == AnalysisType.fullAnalysis
          ? 'full_analysis'
          : 'nutrient_breakdown',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NutritionViewModel>(
      builder: (context, vm, _) {
        final canAnalyse = widget.imagePath != null && _selectedType != null && !vm.isLoading;

        return Scaffold(
          backgroundColor: _kBg,
          body: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────────
              _Header(imagePath: widget.imagePath, heroTag: _heroTag),

              // ── Content ───────────────────────────────────────────────────────
              Expanded(
                child: widget.imagePath == null
                    ? _EmptyState()
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Analysis Type',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select how you want your food analysed',
                              style: GoogleFonts.inter(fontSize: 13, color: _kDim),
                            ),
                            const SizedBox(height: 20),
                            _OptionCard(
                              title: 'Full Analysis',
                              subtitle: 'Calories, macros, vitamins, minerals, allergens & workout context',
                              icon: Icons.analytics_rounded,
                              selected: _selectedType == AnalysisType.fullAnalysis,
                              onTap: () => setState(() => _selectedType = AnalysisType.fullAnalysis),
                            ),
                            const SizedBox(height: 12),
                            _OptionCard(
                              title: 'Nutrient Breakdown',
                              subtitle: 'Detailed macros — protein, carbs, fats and fibre percentages',
                              icon: Icons.pie_chart_rounded,
                              selected: _selectedType == AnalysisType.nutrientBreakdown,
                              onTap: () => setState(() => _selectedType = AnalysisType.nutrientBreakdown),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),

          // ── Analyse button ────────────────────────────────────────────────────
          bottomNavigationBar: widget.imagePath != null
              ? _BottomBar(
                  loading: vm.isLoading,
                  enabled: canAnalyse,
                  onTap: () => _analyse(vm),
                )
              : null,
        );
      },
    );
  }
}

// ── Header with food image ─────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String? imagePath;
  final String heroTag;
  const _Header({required this.imagePath, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        // Food image or placeholder
        SizedBox(
          height: 300 + topPad,
          width: double.infinity,
          child: imagePath != null
              ? Hero(
                  tag: heroTag,
                  child: Image.file(File(imagePath!), fit: BoxFit.cover),
                )
              : Container(color: const Color(0xFF0D0F14)),
        ),
        // Gradient overlay
        Container(
          height: 300 + topPad,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x55000000), Color(0xEE0A0C12)],
            ),
          ),
        ),
        // Back button
        Positioned(
          top: topPad + 12,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 15),
            ),
          ),
        ),
        // Title at bottom of header
        Positioned(
          bottom: 20, left: 20, right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kLime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kLime.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'FOOD SCANNER',
                  style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: _kLime, letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                imagePath != null ? 'Ready to Analyse' : 'No Image Selected',
                style: GoogleFonts.poppins(
                  fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Analysis option card ───────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? _kLime.withValues(alpha: 0.06) : _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _kLime.withValues(alpha: 0.5) : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon box
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: selected
                    ? _kLime.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? _kLime.withValues(alpha: 0.35) : _kBorder,
                ),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? _kLime : Colors.white.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: selected ? 0.55 : 0.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _kLime : Colors.transparent,
                border: Border.all(
                  color: selected ? _kLime : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom CTA bar ─────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  const _BottomBar({required this.loading, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: enabled ? _kLime : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [BoxShadow(color: _kLime.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: enabled ? Colors.black : Colors.white54,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Analysing…',
                  style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: enabled ? Colors.black : Colors.white54,
                  ),
                ),
              ] else ...[
                Icon(Icons.auto_awesome_rounded, size: 18, color: enabled ? Colors.black : Colors.white30),
                const SizedBox(width: 8),
                Text(
                  'Analyse Food',
                  style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: enabled ? Colors.black : Colors.white30,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _kLime.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _kLime.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.camera_alt_rounded, size: 32, color: _kLime.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            Text(
              'No image selected',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Go back and take or pick a photo of your meal to get started',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, height: 1.6, color: _kDim),
            ),
          ],
        ),
      ),
    );
  }
}
