import 'package:fitness/domain/models/workout_streak.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shape returned by `getUserData`.
List<Map<String, dynamic>> userData(List<String> isoDates) => [
      {
        'date_n_duration': [
          for (final d in isoDates) {'date': d, 'duration': 45.0},
        ],
      }
    ];

void main() {
  group('WorkoutStreak.days', () {
    test('counts each distinct calendar day once', () {
      final streak = WorkoutStreak.fromUserData(userData([
        '2026-08-01T07:00:00.000Z',
        '2026-08-02T07:00:00.000Z',
        '2026-08-03T07:00:00.000Z',
      ]));
      expect(streak.days, 3);
    });

    test('two sessions on one day count once', () {
      // The home badge and analytics both showed inflated numbers when a user
      // logged a morning and an evening session on the same date.
      final streak = WorkoutStreak.fromUserData(userData([
        '2026-08-01T07:00:00.000Z',
        '2026-08-01T18:30:00.000Z',
      ]));
      expect(streak.days, 1);
    });

    test('is zero for a user with no sessions', () {
      expect(WorkoutStreak.fromUserData(userData([])).days, 0);
      expect(WorkoutStreak.fromUserData([]).days, 0);
    });

    test('survives malformed rows instead of blanking the streak', () {
      final rows = [
        {
          'date_n_duration': [
            {'date': '2026-08-01T07:00:00.000Z', 'duration': 30.0},
            {'date': 'not-a-date', 'duration': 30.0},
            {'duration': 30.0}, // no date at all
            'garbage',
          ],
        }
      ];
      expect(WorkoutStreak.fromUserData(rows).days, 1);
    });

    test('tolerates a missing date_n_duration key', () {
      expect(WorkoutStreak.fromUserData([{'something_else': 1}]).days, 0);
    });
  });

  group('WorkoutStreak.consecutiveDays', () {
    final asOf = DateTime(2026, 8, 13);

    test('counts a run ending today', () {
      final streak = WorkoutStreak.fromUserData(userData([
        '2026-08-11T07:00:00.000Z',
        '2026-08-12T07:00:00.000Z',
        '2026-08-13T07:00:00.000Z',
      ]));
      expect(streak.consecutiveDays(asOf: asOf), 3);
    });

    test('still counts when today has no workout yet', () {
      // Ending yesterday must not read as a broken streak — the day is not
      // over, so the user has not actually missed it.
      final streak = WorkoutStreak.fromUserData(userData([
        '2026-08-11T07:00:00.000Z',
        '2026-08-12T07:00:00.000Z',
      ]));
      expect(streak.consecutiveDays(asOf: asOf), 2);
    });

    test('is zero once a full day has been missed', () {
      final streak = WorkoutStreak.fromUserData(userData([
        '2026-08-09T07:00:00.000Z',
        '2026-08-10T07:00:00.000Z',
      ]));
      expect(streak.consecutiveDays(asOf: asOf), 0);
    });

    test('stops at the gap rather than counting every day', () {
      final streak = WorkoutStreak.fromUserData(userData([
        '2026-08-01T07:00:00.000Z',
        '2026-08-02T07:00:00.000Z',
        '2026-08-12T07:00:00.000Z',
        '2026-08-13T07:00:00.000Z',
      ]));
      expect(streak.days, 4);
      expect(streak.consecutiveDays(asOf: asOf), 2);
    });
  });
}
