import 'package:fitness/data/models/workout_log/workout_log_model.dart';

/// One logged set, recovered from the free-text notes a session stores.
class LoggedSet {
  final int setNumber;

  /// Null for a timed hold — a plank has no rep count.
  final int? reps;

  /// Null for a rep-based set.
  final int? durationSec;

  /// Null for bodyweight movements.
  final double? weightKg;

  const LoggedSet({
    required this.setNumber,
    this.reps,
    this.durationSec,
    this.weightKg,
  });

  /// Load moved by this set. A bodyweight or timed set contributes nothing —
  /// counting a plank as zero is honest; inventing a bodyweight figure would
  /// silently change the shape of every chart.
  double get volumeKg => (reps ?? 0) * (weightKg ?? 0);

  /// A set logged as 0 reps is one the user skipped, not one they did.
  bool get wasPerformed => (reps ?? 0) > 0 || (durationSec ?? 0) > 0;
}

/// A session reduced to the numbers a chart can plot.
///
/// Sessions currently store everything in one JSONB blob where each set is a
/// substring — `"set 1: 10 reps @ 113kg | set 2: ..."`. Until that is
/// normalised (see doc/workout-data-model.md) anything numeric has to be
/// recovered by parsing, so the parsing lives here rather than in a widget.
class SessionVolume {
  final DateTime date;
  final String? dayLabel;
  final double totalVolumeKg;
  final int setCount;
  final int exerciseCount;
  final int durationMins;

  const SessionVolume({
    required this.date,
    required this.dayLabel,
    required this.totalVolumeKg,
    required this.setCount,
    required this.exerciseCount,
    required this.durationMins,
  });

  /// Matches the set prefix that marks an entry as *performed*.
  ///
  /// The blob interleaves the prescription and the record: the same exercise
  /// appears twice, once with coaching text and once with set data. Only the
  /// latter is real training, and this is the only thing distinguishing them.
  static final RegExp _setPrefix = RegExp(r'set\s*\d+\s*:', caseSensitive: false);

  static final RegExp _setEntry =
      RegExp(r'set\s*(\d+)\s*:\s*(.*)', caseSensitive: false);

  /// Quantity, optional unit, optional per-side marker, optional load.
  /// Covers `10`, `8–10`, `30 sec`, `10 per leg`, `15 each side`.
  static final RegExp _quantity = RegExp(
    r'^(\d+)(?:\s*[–-]\s*\d+)?\s*'
    r'(sec\w*)?\s*'
    r'(?:each\s*side|per\s*leg|each\s*leg|per\s*side)?\s*'
    r'(?:reps?)?\s*'
    r'(?:@\s*([\d.]+)\s*kg)?',
    caseSensitive: false,
  );

  /// Parse the set list out of one exercise entry's notes.
  static List<LoggedSet> parseSets(String? notes) {
    if (notes == null || !_setPrefix.hasMatch(notes)) return const [];

    final sets = <LoggedSet>[];
    for (final chunk in notes.split('|')) {
      final head = _setEntry.firstMatch(chunk.trim());
      if (head == null) continue;

      final number = int.tryParse(head.group(1) ?? '');
      if (number == null) continue;

      final body = (head.group(2) ?? '').trim();
      final q = _quantity.firstMatch(body);
      if (q == null) {
        sets.add(LoggedSet(setNumber: number));
        continue;
      }

      final value = int.tryParse(q.group(1) ?? '');
      final isTimed = (q.group(2) ?? '').isNotEmpty;

      sets.add(LoggedSet(
        setNumber: number,
        reps: isTimed ? null : value,
        durationSec: isTimed ? value : null,
        weightKg: double.tryParse(q.group(3) ?? ''),
      ));
    }
    return sets;
  }

  /// Reduce one session to its totals.
  static SessionVolume fromSession(WorkoutSessionModel session) {
    var volume = 0.0;
    var setCount = 0;
    var exercises = 0;

    for (final entry in session.workoutLogs) {
      final notes = entry['notes'] as String?;
      final sets = parseSets(notes);
      if (sets.isEmpty) continue; // a prescription, not a record

      exercises++;
      for (final s in sets) {
        if (!s.wasPerformed) continue;
        setCount++;
        volume += s.volumeKg;
      }
    }

    return SessionVolume(
      date: session.sessionDate,
      dayLabel: session.dayLabel,
      totalVolumeKg: volume,
      setCount: setCount,
      exerciseCount: exercises,
      durationMins: session.durationMins ?? 0,
    );
  }

  /// Sessions that produced no measurable load — bodyweight-only days, or
  /// sessions saved before set logging existed. Charting them as zero would
  /// read as "you did nothing", so callers drop them.
  bool get hasVolume => totalVolumeKg > 0;

  /// e.g. "12.3t" — tonnes read better than five digits on an axis.
  String get shortVolume {
    if (totalVolumeKg >= 1000) {
      return '${(totalVolumeKg / 1000).toStringAsFixed(1)}t';
    }
    return '${totalVolumeKg.round()}kg';
  }
}
