import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/muscle.dart';
import 'package:fitness/domain/models/muscle_coverage.dart';
import 'package:fitness/domain/models/session_volume.dart';

/// One exercise on the share image: its best set of the session.
class ShareLift {
  final String name;

  /// Null for bodyweight and timed work.
  final double? weightKg;
  final int? reps;
  final int? durationSec;
  final double volumeKg;

  /// Heavier than any earlier session's top set for this exercise.
  final bool isBest;

  const ShareLift({
    required this.name,
    this.weightKg,
    this.reps,
    this.durationSec,
    this.volumeKg = 0,
    this.isBest = false,
  });
}

/// What a workout share image says about one session. The totals are the same
/// ones the history screens show.
class SessionShare {
  final String title;
  final DateTime date;
  final int durationMins;
  final int exercises;
  final int sets;
  final int reps;
  final double volumeKg;

  /// New bests first, then by the load moved. One entry per exercise.
  final List<ShareLift> lifts;

  /// Shade 1–4 per trained muscle slug.
  final Map<String, int> muscleLevels;

  /// The muscles trained most, by display name.
  final List<String> muscles;

  const SessionShare({
    required this.title,
    required this.date,
    this.durationMins = 0,
    this.exercises = 0,
    this.sets = 0,
    this.reps = 0,
    this.volumeKg = 0,
    this.lifts = const [],
    this.muscleLevels = const {},
    this.muscles = const [],
  });

  int get bests => lifts.where((l) => l.isBest).length;
  bool get isEmpty => sets == 0;

  /// [history] is every loaded session; only those from earlier days decide
  /// whether a lift is a new best.
  factory SessionShare.of(WorkoutSessionModel session, {List<WorkoutSessionModel> history = const []}) {
    final totals = SessionVolume.fromSession(session);
    final entries = SessionVolume.exercisesOf(session);

    // The same exercise can be stored twice in a day (logged, then saved
    // again). It is listed once, with its best set.
    final best = <String, LoggedSet>{};
    final names = <String, String>{};
    final volume = <String, double>{};
    var reps = 0;
    for (final e in entries) {
      final key = ExerciseHistory.keyFor(e.name);
      names.putIfAbsent(key, () => e.name);
      volume[key] = (volume[key] ?? 0) + e.volumeKg;
      for (final s in e.sets) {
        if (!s.wasPerformed) continue;
        reps += s.reps ?? 0;
        final current = best[key];
        if (current == null || _beats(s, current)) best[key] = s;
      }
    }

    final day = DateTime(session.sessionDate.year, session.sessionDate.month, session.sessionDate.day);
    final earlierTop = <String, double>{};
    for (final s in history) {
      final d = DateTime(s.sessionDate.year, s.sessionDate.month, s.sessionDate.day);
      if (!d.isBefore(day)) continue;
      for (final e in SessionVolume.exercisesOf(s)) {
        final w = e.topSet?.weightKg;
        if (w == null) continue;
        final key = ExerciseHistory.keyFor(e.name);
        if (w > (earlierTop[key] ?? 0)) earlierTop[key] = w;
      }
    }

    final lifts = [
      for (final entry in best.entries)
        ShareLift(
          name: names[entry.key]!,
          weightKg: (entry.value.weightKg ?? 0) > 0 ? entry.value.weightKg : null,
          reps: entry.value.reps,
          durationSec: entry.value.durationSec,
          volumeKg: volume[entry.key] ?? 0,
          // A first visit is not a record: there was nothing to beat.
          isBest: earlierTop[entry.key] != null && (entry.value.weightKg ?? 0) > earlierTop[entry.key]!,
        )
    ]..sort((a, b) {
        if (a.isBest != b.isBest) return a.isBest ? -1 : 1;
        return b.volumeKg.compareTo(a.volumeKg);
      });

    final coverage = MuscleCoverage.fromSessions([session]);
    final levels = {
      for (final e in coverage.levels.entries)
        if (e.value > 0) e.key: e.value
    };

    final label = session.dayLabel?.trim();
    return SessionShare(
      title: label == null || label.isEmpty ? 'Workout' : label,
      date: day,
      durationMins: totals.durationMins,
      exercises: totals.exerciseCount,
      sets: totals.setCount,
      reps: reps,
      volumeKg: totals.totalVolumeKg,
      lifts: lifts,
      muscleLevels: levels,
      muscles: [
        for (final slug in coverage.ranked.take(3))
          if (Muscle.bySlug(slug) != null) Muscle.bySlug(slug)!.name
      ],
    );
  }

  /// Heavier wins; at the same weight, more reps or a longer hold.
  static bool _beats(LoggedSet a, LoggedSet b) {
    final wa = a.weightKg ?? 0, wb = b.weightKg ?? 0;
    if (wa != wb) return wa > wb;
    return (a.reps ?? a.durationSec ?? 0) > (b.reps ?? b.durationSec ?? 0);
  }
}
