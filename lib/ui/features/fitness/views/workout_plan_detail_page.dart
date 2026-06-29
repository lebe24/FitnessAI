import 'dart:io';
import 'package:fitness/data/services/storage/image_path_resolver.dart';
import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/use_cases/storage/update_fitness_plan_usecase.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg     = Color(0xFF0A0C12);
const _kCard   = Color(0xFF111318);
const _kCard2  = Color(0xFF161B26);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kDim    = Color(0x80FFFFFF);
const _kAmber  = Color(0xFFFFAA00);

class WorkoutPlanDetailPage extends StatefulWidget {
  final StoredFitnessPlanEntity storedPlan;

  const WorkoutPlanDetailPage({super.key, required this.storedPlan});

  @override
  State<WorkoutPlanDetailPage> createState() => _WorkoutPlanDetailPageState();
}

class _WorkoutPlanDetailPageState extends State<WorkoutPlanDetailPage> {
  final _updateUsecase = sl<UpdateFitnessPlanUsecase>();

  late WorkoutPlanData _plan;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _plan = widget.storedPlan.workoutPlan.plan;
  }

  // ── Persistence ───────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_dirty) return;
    setState(() => _saving = true);
    try {
      final updated = widget.storedPlan.copyWith(
        workoutPlan: WorkoutPlanEntity(plan: _plan, status: widget.storedPlan.workoutPlan.status),
      );
      await _updateUsecase(updated);
      if (mounted) {
        setState(() { _dirty = false; _saving = false; });
        _snack('Changes saved', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('Save failed: $e', isError: true);
      }
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF1A2A00),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Day CRUD ──────────────────────────────────────────────────────────────────
  void _addDay() async {
    final result = await showModalBottomSheet<WorkoutDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EditDaySheet(existing: _plan.weeklySplit.days),
    );
    if (result == null) return;
    setState(() {
      _plan = _plan._copyWith(
        weeklySplit: WeeklySplit(days: [..._plan.weeklySplit.days, result]),
      );
      _dirty = true;
    });
  }

  void _editDay(int dayIndex) async {
    final day = _plan.weeklySplit.days[dayIndex];
    final result = await showModalBottomSheet<WorkoutDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EditDaySheet(editDay: day, existing: _plan.weeklySplit.days),
    );
    if (result == null) return;
    final days = List<WorkoutDay>.from(_plan.weeklySplit.days);
    days[dayIndex] = result;
    setState(() {
      _plan = _plan._copyWith(weeklySplit: WeeklySplit(days: days));
      _dirty = true;
    });
  }

  void _deleteDay(int dayIndex) async {
    final day = _plan.weeklySplit.days[dayIndex];
    final confirmed = await _confirmDelete('"${day.day} – ${day.focus}"');
    if (!confirmed) return;
    final days = List<WorkoutDay>.from(_plan.weeklySplit.days)..removeAt(dayIndex);
    setState(() {
      _plan = _plan._copyWith(weeklySplit: WeeklySplit(days: days));
      _dirty = true;
    });
  }

  // ── Exercise CRUD ──────────────────────────────────────────────────────────────
  void _addExercise(int dayIndex) async {
    final result = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _EditExerciseSheet(),
    );
    if (result == null) return;
    final days = List<WorkoutDay>.from(_plan.weeklySplit.days);
    final day = days[dayIndex];
    days[dayIndex] = WorkoutDay(
      day: day.day,
      focus: day.focus,
      exercises: [...day.exercises, result],
      tip: day.tip,
    );
    setState(() {
      _plan = _plan._copyWith(weeklySplit: WeeklySplit(days: days));
      _dirty = true;
    });
  }

  void _editExercise(int dayIndex, int exIndex) async {
    final ex = _plan.weeklySplit.days[dayIndex].exercises[exIndex];
    final result = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EditExerciseSheet(exercise: ex),
    );
    if (result == null) return;
    final days = List<WorkoutDay>.from(_plan.weeklySplit.days);
    final day = days[dayIndex];
    final exercises = List<Exercise>.from(day.exercises);
    exercises[exIndex] = result;
    days[dayIndex] = WorkoutDay(
      day: day.day, focus: day.focus, exercises: exercises, tip: day.tip,
    );
    setState(() {
      _plan = _plan._copyWith(weeklySplit: WeeklySplit(days: days));
      _dirty = true;
    });
  }

  void _deleteExercise(int dayIndex, int exIndex) async {
    final ex = _plan.weeklySplit.days[dayIndex].exercises[exIndex];
    final confirmed = await _confirmDelete('"${ex.name}"');
    if (!confirmed) return;
    final days = List<WorkoutDay>.from(_plan.weeklySplit.days);
    final day = days[dayIndex];
    final exercises = List<Exercise>.from(day.exercises)..removeAt(exIndex);
    days[dayIndex] = WorkoutDay(
      day: day.day, focus: day.focus, exercises: exercises, tip: day.tip,
    );
    setState(() {
      _plan = _plan._copyWith(weeklySplit: WeeklySplit(days: days));
      _dirty = true;
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  Future<bool> _confirmDelete(String label) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => _ConfirmDeleteDialog(label: label),
        ) ==
        true;
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dt = widget.storedPlan.createdAt;
    final dateStr = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero sliver ─────────────────────────────────────────────────
              SliverToBoxAdapter(child: _HeroBanner(
                imagePath: widget.storedPlan.imagePath,
                goal: _plan.goal,
                dateStr: dateStr,
                rating: _plan.physiqueRating,
              )),

              // ── Overview pills ──────────────────────────────────────────────
              SliverToBoxAdapter(child: _OverviewRow(plan: _plan)),

              // ── Analysis summary ────────────────────────────────────────────
              _sectionHeader('Analysis Summary'),
              SliverToBoxAdapter(
                child: _InfoCard(child: Text(
                  _plan.analysisSummary,
                  style: GoogleFonts.inter(fontSize: 13, height: 1.65, color: Colors.white.withValues(alpha: 0.8)),
                )),
              ),

              // ── Weekly split ────────────────────────────────────────────────
              _sectionHeader('Weekly Split', action: _AddButton(onTap: _addDay, label: 'Add Day')),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _WorkoutDayCard(
                    day: _plan.weeklySplit.days[i],
                    dayIndex: i,
                    onEditDay: () => _editDay(i),
                    onDeleteDay: () => _deleteDay(i),
                    onAddExercise: () => _addExercise(i),
                    onEditExercise: (ei) => _editExercise(i, ei),
                    onDeleteExercise: (ei) => _deleteExercise(i, ei),
                  ),
                  childCount: _plan.weeklySplit.days.length,
                ),
              ),

              // ── Training guidelines ─────────────────────────────────────────
              _sectionHeader('Training Guidelines'),
              SliverToBoxAdapter(
                child: _InfoCard(child: Column(
                  children: [
                    _GuideRow(label: 'Rest Between Sets', value: _plan.trainingGuidelines.restBetweenSets),
                    _GuideRow(label: 'Progressive Overload', value: _plan.trainingGuidelines.progressiveOverload),
                    _GuideRow(label: 'Duration', value: _plan.trainingGuidelines.durationWeeks, isLast: true),
                  ],
                )),
              ),

              // ── Nutrition guidelines ────────────────────────────────────────
              _sectionHeader('Nutrition Guidelines'),
              SliverToBoxAdapter(
                child: _InfoCard(child: Column(
                  children: [
                    _GuideRow(label: 'Protein / kg', value: _plan.nutritionGuidelines.proteinPerKg),
                    _GuideRow(label: 'Calorie Surplus', value: _plan.nutritionGuidelines.calorieSurplus),
                    _GuideRow(label: 'Hydration', value: _plan.nutritionGuidelines.hydration),
                    _GuideRow(
                      label: 'Sleep',
                      value: _plan.nutritionGuidelines.sleep,
                      isLast: _plan.nutritionGuidelines.additionalNotes == null,
                    ),
                    if (_plan.nutritionGuidelines.additionalNotes != null)
                      _GuideRow(
                        label: 'Notes',
                        value: _plan.nutritionGuidelines.additionalNotes!,
                        isLast: true,
                      ),
                  ],
                )),
              ),

              // ── Extra tips ──────────────────────────────────────────────────
              if (_plan.extraTips.isNotEmpty) ...[
                _sectionHeader('Extra Tips'),
                SliverToBoxAdapter(
                  child: _InfoCard(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _plan.extraTips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6, height: 6,
                            margin: const EdgeInsets.only(top: 5, right: 10),
                            decoration: const BoxDecoration(color: _kLime, shape: BoxShape.circle),
                          ),
                          Expanded(child: Text(
                            tip,
                            style: GoogleFonts.inter(fontSize: 13, height: 1.6, color: Colors.white.withValues(alpha: 0.8)),
                          )),
                        ],
                      ),
                    )).toList(),
                  )),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // ── Floating save button ────────────────────────────────────────────
          if (_dirty)
            Positioned(
              bottom: 28,
              left: 24,
              right: 24,
              child: _SaveBar(saving: _saving, onSave: _save),
            ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(String title, {Widget? action}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
        child: Row(
          children: [
            Text(title, style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
            )),
            const Spacer(),
            if (action != null) action,
          ],
        ),
      ),
    );
  }
}

// ── Hero banner ───────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final String? imagePath;
  final String goal;
  final String dateStr;
  final double rating;

  const _HeroBanner({
    required this.imagePath,
    required this.goal,
    required this.dateStr,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image / gradient bg
        SizedBox(
          height: 280,
          width: double.infinity,
          child: imagePath != null
              ? FutureBuilder<String?>(
                  future: ImagePathResolver.resolve(imagePath),
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return _placeholder();
                    }
                    final resolved = snap.data;
                    return resolved != null
                        ? Image.file(File(resolved), fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder();
                  },
                )
              : _placeholder(),
        ),
        // Dark gradient overlay
        Container(
          height: 280,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x44000000), Color(0xDD000000)],
            ),
          ),
        ),
        // Safe area back button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
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
              ],
            ),
          ),
        ),
        // Title + meta at bottom of banner
        Positioned(
          bottom: 20, left: 20, right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal,
                style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 12, color: _kDim),
                  const SizedBox(width: 4),
                  Text('Saved $dateStr', style: GoogleFonts.inter(fontSize: 12, color: _kDim)),
                  const SizedBox(width: 14),
                  const Icon(Icons.star_rounded, size: 13, color: _kAmber),
                  const SizedBox(width: 3),
                  Text(
                    rating.toStringAsFixed(1),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _kAmber),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF161B26),
    child: Center(child: Icon(Icons.fitness_center_rounded, size: 48, color: _kLime.withValues(alpha: 0.2))),
  );
}

// ── Overview pills ────────────────────────────────────────────────────────────

class _OverviewRow extends StatelessWidget {
  final WorkoutPlanData plan;
  const _OverviewRow({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: [
          _Pill(icon: Icons.flag_rounded, label: plan.focus, lime: true),
          _Pill(icon: Icons.repeat_rounded, label: plan.trainingSplit),
          _Pill(icon: Icons.calendar_today_rounded, label: '${plan.weeklySplit.days.length} days/week'),
          if (plan.trainingGuidelines.durationWeeks.isNotEmpty)
            _Pill(icon: Icons.timer_outlined, label: plan.trainingGuidelines.durationWeeks),
          ...plan.equipment.take(2).map((e) => _Pill(icon: Icons.fitness_center_rounded, label: e)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool lime;
  const _Pill({required this.icon, required this.label, this.lime = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: lime ? _kLime.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: lime ? _kLime.withValues(alpha: 0.3) : _kBorder),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: lime ? _kLime : _kDim),
      const SizedBox(width: 5),
      Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: lime ? _kLime : _kDim)),
    ]),
  );
}

// ── Info card wrapper ─────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: child,
    ),
  );
}

class _GuideRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  const _GuideRow({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 130,
            child: Text(label, style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.4), letterSpacing: 0.3,
            )),
          ),
          Expanded(child: Text(value, style: GoogleFonts.inter(
            fontSize: 13, height: 1.5, color: Colors.white.withValues(alpha: 0.85),
          ))),
        ]),
        if (!isLast) ...[
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// ── Workout day card ──────────────────────────────────────────────────────────

class _WorkoutDayCard extends StatefulWidget {
  final WorkoutDay day;
  final int dayIndex;
  final VoidCallback onEditDay;
  final VoidCallback onDeleteDay;
  final VoidCallback onAddExercise;
  final void Function(int) onEditExercise;
  final void Function(int) onDeleteExercise;

  const _WorkoutDayCard({
    required this.day,
    required this.dayIndex,
    required this.onEditDay,
    required this.onDeleteDay,
    required this.onAddExercise,
    required this.onEditExercise,
    required this.onDeleteExercise,
  });

  @override
  State<_WorkoutDayCard> createState() => _WorkoutDayCardState();
}

class _WorkoutDayCardState extends State<_WorkoutDayCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: [
            // ── Day header ────────────────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                decoration: BoxDecoration(
                  color: _kCard2,
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(16),
                    bottom: _expanded ? Radius.zero : const Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    // Day badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kLime.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kLime.withValues(alpha: 0.3)),
                      ),
                      child: Text(day.day, style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w800, color: _kLime, letterSpacing: 0.3,
                      )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      day.focus,
                      style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                      ),
                    )),
                    // Exercise count pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${day.exercises.length} ex',
                        style: GoogleFonts.inter(fontSize: 11, color: _kDim),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Edit day
                    _IconBtn(icon: Icons.edit_rounded, onTap: widget.onEditDay),
                    // Delete day
                    _IconBtn(icon: Icons.delete_outline_rounded, onTap: widget.onDeleteDay, danger: true),
                    // Expand chevron
                    AnimatedRotation(
                      turns: _expanded ? 0 : -0.25,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more_rounded,
                          size: 20, color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
            ),

            // ── Exercises ─────────────────────────────────────────────────────
            if (_expanded) ...[
              if (day.exercises.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'No exercises — tap + to add one',
                    style: GoogleFonts.inter(fontSize: 13, color: _kDim),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...day.exercises.asMap().entries.map((e) => _ExerciseRow(
                  exercise: e.value,
                  isLast: e.key == day.exercises.length - 1 && day.tip == null,
                  onEdit: () => widget.onEditExercise(e.key),
                  onDelete: () => widget.onDeleteExercise(e.key),
                )),

              // Tip banner
              if (day.tip != null && day.tip!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kAmber.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kAmber.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_rounded, size: 15, color: _kAmber),
                      const SizedBox(width: 8),
                      Expanded(child: Text(day.tip!, style: GoogleFonts.inter(
                        fontSize: 12, height: 1.5, color: _kAmber,
                      ))),
                    ],
                  ),
                ),

              // Add exercise button
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: GestureDetector(
                  onTap: widget.onAddExercise,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: _kLime.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kLime.withValues(alpha: 0.2)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_rounded, size: 16, color: _kLime),
                      const SizedBox(width: 6),
                      Text('Add Exercise', style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700, color: _kLime,
                      )),
                    ]),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseRow({
    required this.exercise,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: _kLime, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(exercise.name, style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                  )),
                  const SizedBox(height: 3),
                  Text(
                    '${exercise.sets} sets × ${exercise.reps}',
                    style: GoogleFonts.inter(fontSize: 12, color: _kDim),
                  ),
                  if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(exercise.notes!, style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.white.withValues(alpha: 0.35),
                      fontStyle: FontStyle.italic,
                    )),
                  ],
                ]),
              ),
              _IconBtn(icon: Icons.edit_rounded, onTap: onEdit),
              _IconBtn(icon: Icons.delete_outline_rounded, onTap: onDelete, danger: true),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 34, color: Colors.white.withValues(alpha: 0.06)),
      ],
    );
  }
}

// ── Small icon button ─────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  const _IconBtn({required this.icon, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: danger
            ? Colors.red.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 15,
        color: danger
            ? Colors.red.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.45),
      ),
    ),
  );
}

// ── Add button ────────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _AddButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kLime.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kLime.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.add_rounded, size: 13, color: _kLime),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _kLime)),
      ]),
    ),
  );
}

// ── Floating save bar ─────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  const _SaveBar({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: saving ? null : onSave,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _kLime,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _kLime.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 6))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (saving)
          const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
        else
          const Icon(Icons.save_rounded, color: Colors.black, size: 18),
        const SizedBox(width: 10),
        Text(
          saving ? 'Saving…' : 'Save Changes',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
        ),
      ]),
    ),
  );
}

// ── Edit Day sheet ────────────────────────────────────────────────────────────

class _EditDaySheet extends StatefulWidget {
  final WorkoutDay? editDay;
  final List<WorkoutDay> existing;
  const _EditDaySheet({this.editDay, required this.existing});

  @override
  State<_EditDaySheet> createState() => _EditDaySheetState();
}

class _EditDaySheetState extends State<_EditDaySheet> {
  late final TextEditingController _dayCtl;
  late final TextEditingController _focusCtl;
  late final TextEditingController _tipCtl;

  static const _days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];

  @override
  void initState() {
    super.initState();
    _dayCtl   = TextEditingController(text: widget.editDay?.day ?? '');
    _focusCtl = TextEditingController(text: widget.editDay?.focus ?? '');
    _tipCtl   = TextEditingController(text: widget.editDay?.tip ?? '');
  }

  @override
  void dispose() {
    _dayCtl.dispose(); _focusCtl.dispose(); _tipCtl.dispose();
    super.dispose();
  }

  void _submit() {
    final day = _dayCtl.text.trim();
    final focus = _focusCtl.text.trim();
    if (day.isEmpty || focus.isEmpty) return;
    Navigator.of(context).pop(WorkoutDay(
      day: day,
      focus: focus,
      exercises: widget.editDay?.exercises ?? [],
      tip: _tipCtl.text.trim().isEmpty ? null : _tipCtl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0F14),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SheetHandle(),
          const SizedBox(height: 20),
          Text(
            widget.editDay == null ? 'Add Workout Day' : 'Edit Day',
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 20),
          // Day picker chips
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _days.map((d) {
              final selected = _dayCtl.text == d;
              return GestureDetector(
                onTap: () => setState(() => _dayCtl.text = d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? _kLime.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? _kLime.withValues(alpha: 0.4) : _kBorder),
                  ),
                  child: Text(d.substring(0, 3), style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: selected ? _kLime : _kDim,
                  )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _SheetField(controller: _focusCtl, hint: 'Focus (e.g. Chest & Triceps)', label: 'Focus'),
          const SizedBox(height: 12),
          _SheetField(controller: _tipCtl, hint: 'Optional tip for this day', label: 'Day Tip (optional)', maxLines: 2),
          const SizedBox(height: 24),
          _SheetSaveButton(
            label: widget.editDay == null ? 'Add Day' : 'Save Changes',
            onTap: _submit,
          ),
        ]),
      ),
    );
  }
}

// ── Edit Exercise sheet ───────────────────────────────────────────────────────

class _EditExerciseSheet extends StatefulWidget {
  final Exercise? exercise;
  const _EditExerciseSheet({this.exercise});

  @override
  State<_EditExerciseSheet> createState() => _EditExerciseSheetState();
}

class _EditExerciseSheetState extends State<_EditExerciseSheet> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _setsCtl;
  late final TextEditingController _repsCtl;
  late final TextEditingController _notesCtl;

  @override
  void initState() {
    super.initState();
    _nameCtl  = TextEditingController(text: widget.exercise?.name ?? '');
    _setsCtl  = TextEditingController(text: widget.exercise != null ? '${widget.exercise!.sets}' : '');
    _repsCtl  = TextEditingController(text: widget.exercise?.reps ?? '');
    _notesCtl = TextEditingController(text: widget.exercise?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtl.dispose(); _setsCtl.dispose(); _repsCtl.dispose(); _notesCtl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtl.text.trim();
    final sets = int.tryParse(_setsCtl.text.trim()) ?? 3;
    final reps = _repsCtl.text.trim().isNotEmpty ? _repsCtl.text.trim() : '8-12';
    if (name.isEmpty) return;
    Navigator.of(context).pop(Exercise(
      name: name,
      sets: sets,
      reps: reps,
      notes: _notesCtl.text.trim().isEmpty ? null : _notesCtl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0F14),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SheetHandle(),
          const SizedBox(height: 20),
          Text(
            widget.exercise == null ? 'Add Exercise' : 'Edit Exercise',
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 20),
          _SheetField(controller: _nameCtl, hint: 'e.g. Romanian Deadlift', label: 'Exercise Name', autofocus: true),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _SheetField(controller: _setsCtl, hint: '4', label: 'Sets', inputType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _SheetField(controller: _repsCtl, hint: '8-12', label: 'Reps')),
          ]),
          const SizedBox(height: 12),
          _SheetField(controller: _notesCtl, hint: 'e.g. Control the eccentric', label: 'Notes (optional)', maxLines: 2),
          const SizedBox(height: 24),
          _SheetSaveButton(
            label: widget.exercise == null ? 'Add Exercise' : 'Save Exercise',
            onTap: _submit,
          ),
        ]),
      ),
    );
  }
}

// ── Shared sheet sub-widgets ──────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36, height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final int maxLines;
  final TextInputType inputType;
  final bool autofocus;

  const _SheetField({
    required this.controller,
    required this.hint,
    required this.label,
    this.maxLines = 1,
    this.inputType = TextInputType.text,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.4), letterSpacing: 0.4,
      )),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        autofocus: autofocus,
        maxLines: maxLines,
        keyboardType: inputType,
        inputFormatters: inputType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.25)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.04),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kLime, width: 1.5),
          ),
        ),
      ),
    ]);
  }
}

class _SheetSaveButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SheetSaveButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: _kLime,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: _kLime.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Center(child: Text(label, style: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black,
      ))),
    ),
  );
}

// ── Confirm delete dialog ─────────────────────────────────────────────────────

class _ConfirmDeleteDialog extends StatelessWidget {
  final String label;
  const _ConfirmDeleteDialog({required this.label});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
            ),
            child: Icon(Icons.delete_outline_rounded, color: Colors.red.withValues(alpha: 0.8), size: 24),
          ),
          const SizedBox(height: 16),
          Text('Delete $label?', textAlign: TextAlign.center, style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
          )),
          const SizedBox(height: 8),
          Text(
            'This cannot be undone. Tap Save to persist all your changes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, height: 1.5, color: _kDim),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.of(context).pop(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Center(child: Text('Cancel', style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54,
                ))),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.of(context).pop(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
                ),
                child: Center(child: Text('Delete', style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Colors.red.withValues(alpha: 0.9),
                ))),
              ),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ── WorkoutPlanData copyWith extension ────────────────────────────────────────

extension _PlanCopy on WorkoutPlanData {
  WorkoutPlanData _copyWith({WeeklySplit? weeklySplit}) {
    return WorkoutPlanData(
      analysisSummary:    analysisSummary,
      physiqueRating:     physiqueRating,
      goal:               goal,
      focus:              focus,
      trainingSplit:      trainingSplit,
      equipment:          equipment,
      weeklySplit:        weeklySplit ?? this.weeklySplit,
      trainingGuidelines: trainingGuidelines,
      nutritionGuidelines: nutritionGuidelines,
      extraTips:          extraTips,
    );
  }
}
