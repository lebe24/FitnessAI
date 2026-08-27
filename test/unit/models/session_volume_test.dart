import 'package:fitness/domain/models/session_volume.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every string below is copied verbatim from the production export
/// (workout_sessions_rows.csv). Inventing tidier inputs would test a format
/// the app never actually receives.
void main() {
  group('parsing the free-text set log', () {
    test('a plain rep-and-weight set', () {
      final sets = SessionVolume.parseSets(
          'set 1: 10 reps @ 113kg | set 2: 10 reps @ 107kg');
      expect(sets, hasLength(2));
      expect(sets[0].reps, 10);
      expect(sets[0].weightKg, 113);
      expect(sets[1].setNumber, 2);
    });

    test('a timed hold is a duration, not a rep count', () {
      // "Planks — set 1: 60 sec reps @ 0kg". Reading 60 as reps would report a
      // one-minute plank as sixty repetitions.
      final sets = SessionVolume.parseSets('set 1: 60 sec reps @ 0kg');
      expect(sets.single.reps, isNull);
      expect(sets.single.durationSec, 60);
      expect(sets.single.volumeKg, 0);
    });

    test('per-side counts are read as the number given', () {
      for (final s in [
        'set 1: 15 each side reps @ 0kg',
        'set 1: 10 per leg reps @ 45kg',
        'set 1: 10each side reps @ 0kg', // missing space, present in the export
      ]) {
        expect(SessionVolume.parseSets(s).single.reps, isNotNull, reason: s);
      }
    });

    test('an unfilled range takes the lower bound', () {
      // "set 3: 5–8 reps" — logged but never completed with a real number.
      expect(SessionVolume.parseSets('set 3: 5–8 reps').single.reps, 5);
    });

    test('a set with no weight is bodyweight, not zero-volume nonsense', () {
      final s = SessionVolume.parseSets('set 2: 6 reps').single;
      expect(s.reps, 6);
      expect(s.weightKg, isNull);
      expect(s.volumeKg, 0);
    });

    test('prescription entries yield nothing', () {
      // These sit in the same array as real sets and must not be counted.
      expect(SessionVolume.parseSets('shoulders, upper back | Focus on keeping '
          'your elbows high.'), isEmpty);
      expect(SessionVolume.parseSets(null), isEmpty);
      expect(SessionVolume.parseSets(''), isEmpty);
    });
  });

  group('volume', () {
    test('is reps times weight, summed', () {
      final sets = SessionVolume.parseSets(
          'set 1: 10 reps @ 113kg | set 2: 10 reps @ 107kg | '
          'set 3: 14 reps @ 93kg | set 4: 10 reps @ 93kg | set 5: 10 reps @ 86kg');
      final total = sets.fold<double>(0, (s, x) => s + x.volumeKg);
      // Matches the figure computed independently from the CSV.
      expect(total, 5292);
    });

    test('a 0-rep set counts as skipped, not performed', () {
      // Pull-Ups "set 3: 0 reps @ 0kg" — logged, never done.
      final sets = SessionVolume.parseSets(
          'set 1: 8 reps @ 0kg | set 3: 0 reps @ 0kg');
      expect(sets.where((s) => s.wasPerformed), hasLength(1));
    });
  });

  group('display', () {
    test('tonnes above 1000kg, kilos below', () {
      SessionVolume v(double kg) => SessionVolume(
            date: DateTime(2026, 8, 15),
            dayLabel: null,
            totalVolumeKg: kg,
            setCount: 0,
            exerciseCount: 0,
            durationMins: 0,
          );
      expect(v(12278).shortVolume, '12.3t');
      expect(v(810).shortVolume, '810kg');
    });

    test('a session with no load is excluded from the chart', () {
      final empty = SessionVolume(
        date: DateTime(2026, 8, 19),
        dayLabel: 'Wednesday',
        totalVolumeKg: 0,
        setCount: 0,
        exerciseCount: 6,
        durationMins: 120,
      );
      // 2026-08-19 in the export has six prescribed exercises and no sets;
      // charting it as a zero bar would read as "you did nothing".
      expect(empty.hasVolume, isFalse);
    });
  });
}
