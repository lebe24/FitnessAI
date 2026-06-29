import 'dart:io';

import 'package:fitness/data/services/storage/image_path_resolver.dart';
import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/use_cases/storage/delete_fitness_plan_usecase.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/fitness/view_models/fitness_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg     = Color(0xFF0A0C12);
const _kCard   = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kDim    = Color(0x80FFFFFF);

class SavedProgramPage extends StatefulWidget {
  const SavedProgramPage({super.key});

  @override
  State<SavedProgramPage> createState() => _SavedProgramPageState();
}

class _SavedProgramPageState extends State<SavedProgramPage> {
  FitnessViewModel? _vm;
  final _deleteUsecase = sl<DeleteFitnessPlanUsecase>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _vm = context.read<FitnessViewModel>();
      _vm!.addListener(_refresh);
    });
  }

  @override
  void dispose() {
    _vm?.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmDelete(StoredFitnessPlanEntity plan) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteConfirmSheet(planGoal: plan.workoutPlan.plan.goal),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _deleteUsecase(plan.id);
      if (!mounted) return;
      final vm = context.read<FitnessViewModel>();
      await vm.loadFitnessPlans();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Program deleted',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E2A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Could not delete: $e',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = context.watch<FitnessViewModel>().plans;

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _AppBar(),
          if (plans.isEmpty)
            SliverFillRemaining(child: _EmptyState())
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '${plans.length} program${plans.length == 1 ? '' : 's'} saved',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _kDim,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _PlanCard(
                      plan: plans[i],
                      index: i,
                      onDelete: () => _confirmDelete(plans[i]),
                    ),
                  ),
                  childCount: plans.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111318),
          border: Border(bottom: BorderSide(color: _kBorder)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kBorder),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Programs',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your saved workout plans',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _kDim,
                        ),
                      ),
                    ],
                  ),
                ),
                // lime dot badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kLime.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kLime.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center_rounded, size: 12, color: _kLime),
                      const SizedBox(width: 5),
                      Text(
                        'Programs',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kLime,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final StoredFitnessPlanEntity plan;
  final int index;
  final VoidCallback onDelete;
  const _PlanCard({required this.plan, required this.index, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p         = plan.workoutPlan.plan;
    final goal      = p.goal;
    final split     = p.trainingSplit;
    final daysCount = p.weeklySplit.days.length;
    final dt        = plan.createdAt;
    const months    = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr   = '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
    final imagePath = plan.imagePath;

    return GestureDetector(
      onTap: () => context.push('/workout-plan-detail', extra: {'storedPlan': plan}),
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── image banner ─────────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: _PlanImage(imagePath: imagePath),
              ),
            ),

            // ── body ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // goal title
                  Text(
                    goal,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // pill row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Pill(
                        icon: Icons.calendar_today_rounded,
                        label: '$daysCount days/week',
                        lime: true,
                      ),
                      _Pill(
                        icon: Icons.repeat_rounded,
                        label: split,
                      ),
                      if (p.trainingGuidelines.durationWeeks.isNotEmpty)
                        _Pill(
                          icon: Icons.timer_outlined,
                          label: p.trainingGuidelines.durationWeeks,
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // divider
                  Divider(height: 1, thickness: 1, color: _kBorder),

                  const SizedBox(height: 12),

                  // footer: date + delete + open button
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 13, color: _kDim),
                      const SizedBox(width: 5),
                      Text(
                        'Saved $dateStr',
                        style: GoogleFonts.inter(fontSize: 12, color: _kDim),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 17,
                            color: Colors.red.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _kLime,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Plan',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 13, color: Colors.black),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOut);
  }
}

class _PlanImage extends StatelessWidget {
  final String? imagePath;
  const _PlanImage({this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return FutureBuilder<String?>(
        future: ImagePathResolver.resolve(imagePath),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _placeholder();
          }
          final resolved = snap.data;
          return resolved != null
              ? Image.file(File(resolved),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
              : _placeholder();
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF161B26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 40,
              color: _kLime.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Workout Program',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      );
}

// ── Pill chip ─────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool lime;
  const _Pill({required this.icon, required this.label, this.lime = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: lime
              ? _kLime.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: lime
                ? _kLime.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: lime ? _kLime : _kDim),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: lime ? _kLime : _kDim,
              ),
            ),
          ],
        ),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kLime.withValues(alpha: 0.07),
                border: Border.all(color: _kLime.withValues(alpha: 0.2)),
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 36,
                color: _kLime.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No programs yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate a workout plan to see\nyour programs here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.6,
                color: _kDim,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
      );
}

// ── Delete confirmation sheet ─────────────────────────────────────────────────

class _DeleteConfirmSheet extends StatelessWidget {
  final String planGoal;
  const _DeleteConfirmSheet({required this.planGoal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 40),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F14),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // icon
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: Colors.red.withValues(alpha: 0.8),
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Delete Program?',
            style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"$planGoal" will be permanently\nremoved from your saved programs.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13, height: 1.55,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
                    ),
                    child: Center(
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: Colors.red.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
