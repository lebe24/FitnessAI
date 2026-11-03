import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/models/session_volume.dart';

/// How an exercise's best set moved between two sessions.
enum HistoryTrend { up, down, same }

class HistoryChange {
  final HistoryTrend trend;

  /// Ready to show: `+2.5 kg`, `−5 kg`, `+2 reps`, `Same`.
  final String label;

  const HistoryChange(this.trend, this.label);
}

/// What a set looks like to a person: `10 × 60 kg`, `12 reps`, `45 sec`.
extension LoggedSetLabel on LoggedSet {
  String get label {
    if (durationSec != null) return '$durationSec sec';
    final r = reps ?? 0;
    final w = weightKg;
    return w == null ? '$r reps' : '$r × ${formatKg(w)} kg';
  }

  /// Bare numbers, for pre-filling a text field.
  String? get weightText => weightKg == null ? null : formatKg(weightKg!);
  String? get repsText => reps?.toString();
}

/// `60` rather than `60.0`; `62.5` stays `62.5`.
String formatKg(double kg) =>
    kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);

/// One earlier visit to an exercise: the day, and the sets that were done.
class ExerciseHistoryEntry {
  final DateTime date;
  final String? dayLabel;

  /// Only sets that were actually performed — a set logged as 0 reps was
  /// skipped, and showing it would make a missed set look like an attempt.
  final List<LoggedSet> sets;

  const ExerciseHistoryEntry({
    required this.date,
    required this.dayLabel,
    required this.sets,
  });

  double get volumeKg => sets.fold(0.0, (t, s) => t + s.volumeKg);

  bool get hasLoad => sets.any((s) => s.weightKg != null);

  /// The set people look for: the heaviest one, and for bodyweight or timed
  /// work, the one with the most reps (or seconds).
  LoggedSet? get bestSet {
    if (sets.isEmpty) return null;
    if (hasLoad) {
      LoggedSet? best;
      for (final s in sets) {
        final w = s.weightKg;
        if (w == null) continue;
        if (best == null ||
            w > best.weightKg! ||
            (w == best.weightKg! && (s.reps ?? 0) > (best.reps ?? 0))) {
          best = s;
        }
      }
      return best;
    }
    return sets.reduce((a, b) => _effort(b) > _effort(a) ? b : a);
  }

  static int _effort(LoggedSet s) => s.reps ?? s.durationSec ?? 0;

  /// How this visit compares with [older]. Null when there is nothing fair to
  /// compare — say, one session with a load and one without.
  HistoryChange? changeFrom(ExerciseHistoryEntry older) {
    final a = bestSet, b = older.bestSet;
    if (a == null || b == null) return null;

    if (a.weightKg != null && b.weightKg != null) {
      final d = a.weightKg! - b.weightKg!;
      if (d == 0) return const HistoryChange(HistoryTrend.same, 'Same');
      final text = '${d > 0 ? '+' : '−'}${formatKg(d.abs())} kg';
      return HistoryChange(d > 0 ? HistoryTrend.up : HistoryTrend.down, text);
    }

    if (a.weightKg == null && b.weightKg == null) {
      final d = _effort(a) - _effort(b);
      if (d == 0) return const HistoryChange(HistoryTrend.same, 'Same');
      final unit = a.durationSec != null ? 'sec' : 'reps';
      return HistoryChange(
          d > 0 ? HistoryTrend.up : HistoryTrend.down,
          '${d > 0 ? '+' : '−'}${d.abs()} $unit');
    }
    return null;
  }
}

/// Everything the user has logged for one exercise, newest first.
///
/// Built from the sessions the app already reads. Sets are stored as free text
/// inside each session's `workout_logs` (see doc/workout-data-model.md), so
/// this leans on [SessionVolume] to recover them rather than re-parsing here.
class ExerciseHistory {
  final List<ExerciseHistoryEntry> entries;

  const ExerciseHistory(this.entries);

  static const empty = ExerciseHistory([]);

  bool get isEmpty => entries.isEmpty;
  int get length => entries.length;

  ExerciseHistoryEntry? get last => entries.isEmpty ? null : entries.first;

  /// The change shown on entry [i], against the next older one.
  HistoryChange? changeAt(int i) =>
      i + 1 < entries.length ? entries[i].changeFrom(entries[i + 1]) : null;

  /// Names are typed by an AI, so "Pull-Ups", "Pull-up" and "pull ups" are one
  /// exercise. Lower-case, drop everything but letters and digits, and fold a
  /// plural s. Deliberately no cleverer: "Back Squat" and "Barbell Squat" are
  /// different movements and must not be merged.
  static String keyFor(String name) {
    final k = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return k.length > 4 && k.endsWith('s') ? k.substring(0, k.length - 1) : k;
  }

  static ExerciseHistory fromSessions(
    List<WorkoutSessionModel> sessions,
    String exerciseName, {
    int limit = 20,
  }) {
    final key = keyFor(exerciseName);
    if (key.isEmpty) return empty;

    final found = <ExerciseHistoryEntry>[];
    for (final session in sessions) {
      for (final ex in SessionVolume.exercisesOf(session)) {
        if (keyFor(ex.name) != key) continue;
        final performed = ex.sets.where((s) => s.wasPerformed).toList();
        if (performed.isEmpty) continue;
        found.add(ExerciseHistoryEntry(
          date: DateTime(session.sessionDate.year, session.sessionDate.month,
              session.sessionDate.day),
          dayLabel: session.dayLabel,
          sets: performed,
        ));
      }
    }

    // Newest first. Dart's sort is not stable, so ties keep their input order
    // by sorting on the index as well.
    final indexed = [for (var i = 0; i < found.length; i++) (i, found[i])]
      ..sort((x, y) {
        final byDate = y.$2.date.compareTo(x.$2.date);
        return byDate != 0 ? byDate : x.$1.compareTo(y.$1);
      });

    // One workout can be saved twice — once when the exercise is logged and
    // again when the whole session is completed — so the same day and the same
    // sets are one visit, not two.
    final seen = <String>{};
    final unique = <ExerciseHistoryEntry>[];
    for (final (_, e) in indexed) {
      final signature = '${e.date.toIso8601String()}|'
          '${e.sets.map((s) => '${s.reps}:${s.durationSec}:${s.weightKg}').join(',')}';
      if (seen.add(signature)) unique.add(e);
    }

    return ExerciseHistory(unique.take(limit).toList());
  }
}
