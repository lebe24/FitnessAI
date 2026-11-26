import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/muscle_coverage.dart';

/// How a muscle group stands, from the colours of the development map.
enum MuscleLevel {
  /// Trained well, and strength is holding or rising. Lime.
  strong,

  /// A reasonable amount of work. Blue.
  average,

  /// Behind where it should be, or pinned by the user. Amber.
  focus,

  /// Nothing logged and nothing scanned. Grey.
  untrained,
}

class MuscleStatus {
  final MuscleGroup group;
  final MuscleLevel level;

  /// 1–10, the scale the body-composition scan uses, so the two read alike.
  final int score;
  final double weeklySets;
  final double targetSets;

  /// Change in estimated strength over the window, in percent. Null when there
  /// is not enough history on both halves to compare.
  final double? strengthTrendPct;
  final int? daysSinceTrained;
  final bool pinned;

  /// One plain sentence saying why, built from the numbers above.
  final String reason;

  const MuscleStatus({
    required this.group,
    required this.level,
    required this.score,
    required this.weeklySets,
    required this.targetSets,
    required this.strengthTrendPct,
    required this.daysSinceTrained,
    required this.pinned,
    required this.reason,
  });
}

/// Reads the last four weeks of sessions and says which muscle groups are
/// strong, average or behind.
///
/// Deterministic and explainable on purpose. The score is how much of a
/// goal-based weekly set target was hit, nudged by whether strength is rising
/// and by how recently the group was trained, then blended with the latest
/// body-scan score when there is one (the scan sees development the logs
/// cannot). Everything the AI says about muscles starts from these numbers.
class MuscleFocus {
  MuscleFocus._();

  static const windowDays = 28;

  /// Working sets a week a group needs for the goal. Small groups get 70% of
  /// it because the big lifts already train them.
  static double targetSets(MuscleGroup group, GoalType? goal) {
    final base = switch (goal) {
      GoalType.buildMuscle || GoalType.gainWeight => 12.0,
      GoalType.loseWeight => 9.0,
      GoalType.maintain => 6.0,
      null => 10.0,
    };
    return group.isLarge ? base : (base * 0.7 * 10).round() / 10;
  }

  static List<MuscleStatus> analyse({
    required List<WorkoutSessionModel> sessions,
    required DateTime now,
    GoalType? goal,
    Set<MuscleGroup> pinned = const {},
    Map<MuscleGroup, int> scanScores = const {},
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: windowDays));
    final recent = [
      for (final s in sessions)
        if (!_day(s.sessionDate).isBefore(from)) s
    ];

    final coverage = MuscleCoverage.fromSessions(recent);

    // When each group was last trained, from the newest session that touched it.
    final lastTrained = <MuscleGroup, DateTime>{};
    for (final s in recent) {
      final load = MuscleCoverage.fromSessions([s]).load;
      for (final entry in load.entries) {
        final g = MuscleGroup.forSlug(entry.key);
        if (g == null || entry.value <= 0) continue;
        final d = _day(s.sessionDate);
        final prev = lastTrained[g];
        if (prev == null || d.isAfter(prev)) lastTrained[g] = d;
      }
    }

    return [
      for (final g in MuscleGroup.values)
        _status(g, coverage, recent, today, goal, pinned.contains(g), scanScores[g], lastTrained[g]),
    ];
  }

  static MuscleStatus _status(
    MuscleGroup group,
    MuscleCoverage coverage,
    List<WorkoutSessionModel> recent,
    DateTime today,
    GoalType? goal,
    bool pinned,
    int? scanScore,
    DateTime? last,
  ) {
    // The most-worked slug stands for the group: summing would count one
    // exercise twice when it names two slugs of the same group.
    var load = 0.0;
    final exercises = <String>{};
    for (final slug in group.slugs) {
      final v = coverage.load[slug] ?? 0;
      if (v > load) load = v;
      exercises.addAll(coverage.byExercise[slug]?.keys ?? const []);
    }
    final weekly = load / (windowDays / 7);
    final target = targetSets(group, goal);
    final trend = _strengthTrend(exercises, recent, today);
    final since = last == null ? null : today.difference(last).inDays;

    final trained = weekly > 0;
    var score = trained ? (1 + 9 * (weekly / target).clamp(0.0, 1.0)).round() : 1;
    if (trained) {
      if (trend != null && trend >= 2) score += 1;
      if (trend != null && trend <= -3) score -= 1;
      if (since != null && since > 10) score -= 1;
    }
    if (scanScore != null) score = (0.6 * score + 0.4 * scanScore).round();
    score = score.clamp(1, 10);

    final MuscleLevel level;
    if (pinned) {
      level = MuscleLevel.focus;
    } else if (!trained && scanScore == null) {
      level = MuscleLevel.untrained;
    } else if (score >= 8) {
      level = MuscleLevel.strong;
    } else if (score >= 5) {
      level = MuscleLevel.average;
    } else {
      level = MuscleLevel.focus;
    }

    return MuscleStatus(
      group: group,
      level: level,
      score: score,
      weeklySets: (weekly * 10).round() / 10,
      targetSets: target,
      strengthTrendPct: trend == null ? null : (trend * 10).round() / 10,
      daysSinceTrained: since,
      pinned: pinned,
      reason: _reason(trained, weekly, target, goal, trend, since),
    );
  }

  /// Change in best estimated one-rep max, last two weeks against the two
  /// before, averaged over the group's exercises that have both.
  static double? _strengthTrend(
      Set<String> exercises, List<WorkoutSessionModel> recent, DateTime today) {
    final split = today.subtract(const Duration(days: windowDays ~/ 2));
    final changes = <double>[];
    for (final name in exercises) {
      final history = ExerciseHistory.fromSessions(recent, name, limit: 40);
      double? newer, older;
      for (final e in history.entries) {
        final best = _bestE1rm(e);
        if (best == null) continue;
        if (e.date.isBefore(split)) {
          if (older == null || best > older) older = best;
        } else {
          if (newer == null || best > newer) newer = best;
        }
      }
      if (newer != null && older != null && older > 0) {
        changes.add((newer / older - 1) * 100);
      }
    }
    if (changes.isEmpty) return null;
    return changes.reduce((a, b) => a + b) / changes.length;
  }

  /// Epley estimate of a one-rep max from the best loaded set of a visit.
  static double? _bestE1rm(ExerciseHistoryEntry e) {
    double? best;
    for (final s in e.sets) {
      final w = s.weightKg, r = s.reps;
      if (w == null || w <= 0 || r == null || r <= 0) continue;
      final v = w * (1 + r / 30);
      if (best == null || v > best) best = v;
    }
    return best;
  }

  static String _reason(bool trained, double weekly, double target, GoalType? goal,
      double? trend, int? since) {
    if (!trained) return 'No sets logged in the last four weeks.';
    final purpose = switch (goal) {
      GoalType.buildMuscle || GoalType.gainWeight => 'building muscle',
      GoalType.loseWeight => 'keeping muscle while you lose weight',
      GoalType.maintain => 'maintaining',
      null => 'steady progress',
    };
    final parts = [
      '${_n(weekly)} sets a week against about ${_n(target)} for $purpose.',
    ];
    if (trend != null && trend.abs() >= 1) {
      parts.add('Strength is ${trend > 0 ? 'up' : 'down'} ${_n(trend.abs())}%.');
    }
    if (since != null && since > 10) parts.add('Last trained $since days ago.');
    return parts.join(' ');
  }

  static String _n(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
