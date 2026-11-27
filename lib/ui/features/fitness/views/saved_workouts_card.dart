import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_events.dart';
import 'package:fitness/domain/models/workout_day_mapping.dart';
import 'package:fitness/l10n/generated/app_localizations.dart';
import 'package:fitness/ui/features/fitness/view_models/fitness_view_model.dart';
import 'package:fitness/ui/features/fitness/views/saved_program.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _kCard   = Color(0xFF111318);
const _kRow    = Color(0xFF141821);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kMuted  = Color(0xFF8C909B);
const _kGreen  = Color(0xFF1ACA31);
const _kAmber  = Color(0xFFFFAA00);

/// The "My Workout Program" card on the home screen: this week's sessions at
/// a glance, and the way into [SavedProgramPage] for the saved plans.
///
/// Requires a [FitnessViewModel] above it in the tree.
class SavedWorkoutsCard extends StatelessWidget {
  const SavedWorkoutsCard({super.key});

  /// Up to [max] sessions to list: this week's, with the window kept around
  /// today so the next session is never pushed off by a busy week. When the
  /// week holds nothing, the next sessions ahead instead.
  static List<WorkoutDayMappingEntity> sessionsFor(
    Map<DateTime, WorkoutDayMappingEntity> mappings,
    DateTime now, {
    int max = 4,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    DateTime day(WorkoutDayMappingEntity m) =>
        DateTime(m.date.year, m.date.month, m.date.day);

    final planned = mappings.values.where((m) => m.hasWorkout).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final week = planned
        .where((m) => !day(m).isBefore(weekStart) && day(m).isBefore(weekEnd))
        .toList();
    if (week.isEmpty) {
      return planned.where((m) => !day(m).isBefore(today)).take(max).toList();
    }
    if (week.length <= max) return week;

    // Two sessions of context before the next one, as the design shows.
    final next = week.indexWhere((m) => !day(m).isBefore(today));
    final first = next < 0 ? week.length - 1 : next;
    final start = (first - 2).clamp(0, week.length - max);
    return week.sublist(start, start + max);
  }

  @override
  Widget build(BuildContext context) {
    // watch, not read: the card must repaint once plans finish loading,
    // otherwise it can sit on a stale empty state.
    final fitnessVm = context.watch<FitnessViewModel>();

    return WorkoutProgramCardView(
      sessions: sessionsFor(fitnessVm.workoutMappings, DateTime.now()),
      completedDates: fitnessVm.completedDates,
      viewAllLabel: AppLocalizations.of(context).viewAllAction,
      onTap: () {
        Analytics.track(AnalyticsEvents.homeCardTapped,
            {'card': 'workout_program', 'locked': false});
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: fitnessVm,
              child: const SavedProgramPage(),
            ),
          ),
        );
      },
    );
  }
}

/// The card itself, with no app services behind it, so it can be shown and
/// tested on its own.
class WorkoutProgramCardView extends StatelessWidget {
  final List<WorkoutDayMappingEntity> sessions;
  final Set<DateTime> completedDates;
  final String viewAllLabel;
  final VoidCallback onTap;

  const WorkoutProgramCardView({
    super.key,
    required this.sessions,
    required this.completedDates,
    required this.viewAllLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Semantics(
      button: true,
      label: 'My Workout Program. $viewAllLabel.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'My Workout Program',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      viewAllLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kLime,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (sessions.isEmpty)
                const _EmptyProgram()
              else
                for (var i = 0; i < sessions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  _SessionRow(
                    session: sessions[i],
                    isToday: _sameDay(sessions[i].date, today),
                    isCompleted: completedDates.any((d) => _sameDay(d, sessions[i].date)),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _SessionRow extends StatelessWidget {
  final WorkoutDayMappingEntity session;
  final bool isToday;
  final bool isCompleted;
  const _SessionRow({
    required this.session,
    required this.isToday,
    required this.isCompleted,
  });

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final day = session.workoutDay!;
    final count = day.exercises.length;
    final dayName = _days[session.date.weekday - 1];

    final Widget trailing;
    if (isCompleted) {
      trailing = const Icon(Icons.check_circle_outline_rounded,
          size: 20, color: _kGreen, semanticLabel: 'Completed');
    } else if (isToday) {
      trailing = Text('Training',
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: _kAmber));
    } else {
      trailing = Text(count == 1 ? '1 exercise' : '$count exercises',
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: _kMuted));
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _kRow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              dayName,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isCompleted ? _kMuted : _kLime,
              ),
            ),
          ),
          Expanded(
            child: Text(
              day.focus,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _EmptyProgram extends StatelessWidget {
  const _EmptyProgram();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: _kRow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.fitness_center_rounded, color: _kMuted, size: 22),
          const SizedBox(height: 8),
          Text(
            'No workouts scheduled',
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Generate a plan and your week shows up here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
          ),
        ],
      ),
    );
  }
}
