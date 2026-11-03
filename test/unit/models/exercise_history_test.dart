import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/session_volume.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSessionModel session(DateTime date, List<Map<String, dynamic>> logs) =>
    WorkoutSessionModel(sessionDate: date, workoutLogs: logs);

Map<String, dynamic> logged(String name, String sets) =>
    {'name': name, 'sets': 3, 'reps': '8', 'notes': sets};

Map<String, dynamic> planned(String name) =>
    {'name': name, 'sets': 3, 'reps': '8', 'notes': 'back, biceps | Lead with your chest'};

ExerciseHistory history(List<WorkoutSessionModel> s, String name,
        {int limit = 20}) =>
    ExerciseHistory.fromSessions(s, name, limit: limit);

void main() {
  group('finding the right exercise', () {
    test('treats spelling and plural variants of one name as the same exercise', () {
      final sessions = [
        session(DateTime(2026, 10, 20), [logged('Pull-Ups', 'set 1: 8 reps')]),
        session(DateTime(2026, 10, 18), [logged('pull up', 'set 1: 7 reps')]),
        session(DateTime(2026, 10, 16), [logged('Pull Ups', 'set 1: 6 reps')]),
      ];
      expect(history(sessions, 'Pull-ups').length, 3);
    });

    test('does not merge different movements that share a word', () {
      final sessions = [
        session(DateTime(2026, 10, 20), [logged('Barbell Squat', 'set 1: 5 reps @ 100kg')]),
        session(DateTime(2026, 10, 18), [logged('Back Squat', 'set 1: 5 reps @ 90kg')]),
      ];
      expect(history(sessions, 'Barbell Squat').length, 1);
    });

    test('ignores the prescription: only entries with set data count', () {
      final sessions = [
        session(DateTime(2026, 10, 20), [
          planned('Pull-Ups'),
          logged('Pull-Ups', 'set 1: 8 reps'),
        ]),
      ];
      expect(history(sessions, 'Pull-Ups').length, 1);
    });

    test('skips sets logged as zero reps — those were not done', () {
      final sessions = [
        session(DateTime(2026, 10, 20), [
          logged('Bench Press', 'set 1: 8 reps @ 60kg | set 2: 0 reps @ 60kg'),
        ]),
      ];
      expect(history(sessions, 'Bench Press').last!.sets.length, 1);
    });

    test('a visit with no performed sets is not a visit', () {
      final sessions = [
        session(DateTime(2026, 10, 20), [logged('Bench Press', 'set 1: 0 reps')]),
      ];
      expect(history(sessions, 'Bench Press').isEmpty, isTrue);
    });

    test('an exercise never logged gives an empty history', () {
      final sessions = [
        session(DateTime(2026, 10, 20), [logged('Bench Press', 'set 1: 8 reps')]),
      ];
      expect(history(sessions, 'Deadlift').isEmpty, isTrue);
      expect(history(sessions, '').isEmpty, isTrue);
    });
  });

  group('ordering and size', () {
    test('is newest first whatever order the sessions arrive in', () {
      final sessions = [
        session(DateTime(2026, 10, 10), [logged('Squat', 'set 1: 5 reps @ 80kg')]),
        session(DateTime(2026, 10, 24), [logged('Squat', 'set 1: 5 reps @ 90kg')]),
        session(DateTime(2026, 10, 17), [logged('Squat', 'set 1: 5 reps @ 85kg')]),
      ];
      final h = history(sessions, 'Squat');
      expect(h.entries.map((e) => e.date.day), [24, 17, 10]);
      expect(h.last!.sets.single.weightKg, 90);
    });

    test('keeps only the most recent entries up to the limit', () {
      final sessions = [
        for (var d = 1; d <= 10; d++)
          session(DateTime(2026, 10, d), [logged('Squat', 'set 1: 5 reps @ ${d}0kg')]),
      ];
      final h = history(sessions, 'Squat', limit: 4);
      expect(h.length, 4);
      expect(h.entries.first.date.day, 10);
    });
  });

  group('duplicates', () {
    test('the same workout saved twice on one day is one visit', () {
      // Logged from the exercise page, then again when the workout finished.
      final sessions = [
        session(DateTime(2026, 10, 20), [logged('Squat', 'set 1: 5 reps @ 90kg | set 2: 5 reps @ 90kg')]),
        session(DateTime(2026, 10, 20), [logged('Squat', 'set 1: 5 reps @ 90kg | set 2: 5 reps @ 90kg')]),
      ];
      expect(history(sessions, 'Squat').length, 1);
    });

    test('two genuinely different workouts on one day are both kept', () {
      final sessions = [
        session(DateTime(2026, 10, 20), [logged('Squat', 'set 1: 5 reps @ 90kg')]),
        session(DateTime(2026, 10, 20), [logged('Squat', 'set 1: 5 reps @ 60kg')]),
      ];
      expect(history(sessions, 'Squat').length, 2);
    });
  });

  group('best set and change', () {
    ExerciseHistoryEntry entry(String notes) => history(
            [session(DateTime(2026, 10, 1), [logged('X', notes)])], 'X')
        .last!;

    test('the best set is the heaviest, with reps breaking a tie', () {
      final e = entry('set 1: 10 reps @ 60kg | set 2: 6 reps @ 80kg | set 3: 8 reps @ 80kg');
      expect(e.bestSet!.weightKg, 80);
      expect(e.bestSet!.reps, 8);
    });

    test('for bodyweight work the best set is the most reps', () {
      final e = entry('set 1: 8 reps | set 2: 11 reps | set 3: 9 reps');
      expect(e.bestSet!.reps, 11);
      expect(e.hasLoad, isFalse);
    });

    test('volume adds up reps times weight', () {
      final e = entry('set 1: 10 reps @ 60kg | set 2: 10 reps @ 50kg');
      expect(e.volumeKg, 1100);
    });

    test('reports a heavier top set as up, with the difference', () {
      final newer = entry('set 1: 5 reps @ 82.5kg');
      final older = entry('set 1: 5 reps @ 80kg');
      final c = newer.changeFrom(older)!;
      expect(c.trend, HistoryTrend.up);
      expect(c.label, '+2.5 kg');
    });

    test('reports a lighter top set as down', () {
      final c = entry('set 1: 5 reps @ 70kg').changeFrom(entry('set 1: 5 reps @ 80kg'))!;
      expect(c.trend, HistoryTrend.down);
      expect(c.label, '−10 kg');
    });

    test('reports an unchanged top set as same', () {
      final c = entry('set 1: 5 reps @ 80kg').changeFrom(entry('set 1: 8 reps @ 80kg'))!;
      expect(c.trend, HistoryTrend.same);
    });

    test('compares reps for bodyweight exercises', () {
      final c = entry('set 1: 12 reps').changeFrom(entry('set 1: 10 reps'))!;
      expect(c.trend, HistoryTrend.up);
      expect(c.label, '+2 reps');
    });

    test('compares seconds for holds', () {
      final c = entry('set 1: 45 sec').changeFrom(entry('set 1: 60 sec'))!;
      expect(c.trend, HistoryTrend.down);
      expect(c.label, '−15 sec');
    });

    test('will not compare a loaded session with an unloaded one', () {
      expect(entry('set 1: 8 reps @ 60kg').changeFrom(entry('set 1: 8 reps')), isNull);
    });

    test('the oldest entry has no change to show', () {
      final h = history([
        session(DateTime(2026, 10, 2), [logged('X', 'set 1: 5 reps @ 80kg')]),
        session(DateTime(2026, 10, 1), [logged('X', 'set 1: 5 reps @ 75kg')]),
      ], 'X');
      expect(h.changeAt(0)!.label, '+5 kg');
      expect(h.changeAt(1), isNull);
    });
  });

  group('labels', () {
    test('formats a set the way people say it', () {
      expect(const LoggedSet(setNumber: 1, reps: 10, weightKg: 60).label, '10 × 60 kg');
      expect(const LoggedSet(setNumber: 1, reps: 10, weightKg: 62.5).label, '10 × 62.5 kg');
      expect(const LoggedSet(setNumber: 1, reps: 12).label, '12 reps');
      expect(const LoggedSet(setNumber: 1, durationSec: 45).label, '45 sec');
    });

    test('formatKg drops a pointless decimal', () {
      expect(formatKg(60), '60');
      expect(formatKg(60.0), '60');
      expect(formatKg(62.5), '62.5');
    });

    test('field text is bare numbers, empty when there is none', () {
      const s = LoggedSet(setNumber: 1, reps: 8, weightKg: 60);
      expect(s.weightText, '60');
      expect(s.repsText, '8');
      expect(const LoggedSet(setNumber: 1, reps: 8).weightText, isNull);
    });
  });
}
