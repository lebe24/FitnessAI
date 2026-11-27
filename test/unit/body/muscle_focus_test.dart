import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/muscle_focus.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 25, 9);

String _sets(int n, int reps, num kg) =>
    [for (var i = 1; i <= n; i++) 'set $i: $reps reps @ ${kg}kg'].join(' | ');

WorkoutSessionModel _session(int daysAgo, List<(String, String)> exercises) => WorkoutSessionModel(
      sessionDate: DateTime(2026, 11, 25).subtract(Duration(days: daysAgo)),
      workoutLogs: [
        for (final (name, notes) in exercises) {'name': name, 'sets': 3, 'reps': '8', 'notes': notes}
      ],
    );

MuscleStatus _of(List<MuscleStatus> all, MuscleGroup g) => all.firstWhere((s) => s.group == g);

List<MuscleStatus> _run(List<WorkoutSessionModel> s,
        {GoalType? goal = GoalType.buildMuscle,
        Set<MuscleGroup> pinned = const {},
        Map<MuscleGroup, int> scan = const {}}) =>
    MuscleFocus.analyse(sessions: s, now: _now, goal: goal, pinned: pinned, scanScores: scan);

void main() {
  group('targets', () {
    test('follow the goal, and small groups need less', () {
      expect(MuscleFocus.targetSets(MuscleGroup.chest, GoalType.buildMuscle), 12);
      expect(MuscleFocus.targetSets(MuscleGroup.biceps, GoalType.buildMuscle), 8.4);
      expect(MuscleFocus.targetSets(MuscleGroup.chest, GoalType.maintain), 6);
      expect(MuscleFocus.targetSets(MuscleGroup.chest, null), 10);
    });
  });

  group('scoring', () {
    test('a group with no sets is untrained', () {
      final all = _run(const []);
      expect(all.length, MuscleGroup.values.length);
      expect(all.every((s) => s.level == MuscleLevel.untrained), isTrue);
      expect(_of(all, MuscleGroup.chest).reason, contains('No sets logged'));
    });

    test('hitting the weekly target is strong', () {
      // 12 sets a week for four weeks: 4 sessions of 12 bench sets.
      final s = [for (var w = 0; w < 4; w++) _session(2 + w * 7, [('Bench Press', _sets(12, 8, 60))])];
      final chest = _of(_run(s), MuscleGroup.chest);
      expect(chest.weeklySets, 12);
      expect(chest.score, 10);
      expect(chest.level, MuscleLevel.strong);
    });

    test('half the target is average', () {
      final s = [for (var w = 0; w < 4; w++) _session(2 + w * 7, [('Bench Press', _sets(6, 8, 60))])];
      final chest = _of(_run(s), MuscleGroup.chest);
      expect(chest.weeklySets, 6);
      expect(chest.level, MuscleLevel.average);
    });

    test('a quarter of the target needs focus', () {
      final s = [for (var w = 0; w < 4; w++) _session(2 + w * 7, [('Bench Press', _sets(3, 8, 60))])];
      expect(_of(_run(s), MuscleGroup.chest).level, MuscleLevel.focus);
    });

    test('the same sets count for less when the goal asks for more', () {
      final s = [for (var w = 0; w < 4; w++) _session(2 + w * 7, [('Bench Press', _sets(6, 8, 60))])];
      final maintain = _of(_run(s, goal: GoalType.maintain), MuscleGroup.chest);
      final build = _of(_run(s, goal: GoalType.buildMuscle), MuscleGroup.chest);
      expect(maintain.score, greaterThan(build.score));
    });

    test('assisting muscles get half credit', () {
      final s = [for (var w = 0; w < 4; w++) _session(2 + w * 7, [('Bench Press', _sets(10, 8, 60))])];
      final all = _run(s);
      expect(_of(all, MuscleGroup.chest).weeklySets, 10);
      expect(_of(all, MuscleGroup.triceps).weeklySets, 5);
    });

    test('sessions older than four weeks do not count', () {
      final s = [_session(40, [('Bench Press', _sets(12, 8, 60))])];
      expect(_of(_run(s), MuscleGroup.chest).level, MuscleLevel.untrained);
    });
  });

  group('strength trend', () {
    List<WorkoutSessionModel> bench(double olderKg, double newerKg) => [
          _session(25, [('Bench Press', _sets(4, 8, olderKg))]),
          _session(18, [('Bench Press', _sets(4, 8, olderKg))]),
          _session(5, [('Bench Press', _sets(4, 8, newerKg))]),
          _session(2, [('Bench Press', _sets(4, 8, newerKg))]),
        ];

    test('rising strength is reported and lifts the score', () {
      final up = _of(_run(bench(60, 66)), MuscleGroup.chest);
      final flat = _of(_run(bench(60, 60)), MuscleGroup.chest);
      expect(up.strengthTrendPct, closeTo(10, 0.1));
      expect(up.score, greaterThan(flat.score));
      expect(up.reason, contains('Strength is up'));
    });

    test('falling strength lowers the score', () {
      final down = _of(_run(bench(60, 54)), MuscleGroup.chest);
      final flat = _of(_run(bench(60, 60)), MuscleGroup.chest);
      expect(down.score, lessThan(flat.score));
    });

    test('is unknown without history in both halves', () {
      final s = [_session(3, [('Bench Press', _sets(4, 8, 60))])];
      expect(_of(_run(s), MuscleGroup.chest).strengthTrendPct, isNull);
    });
  });

  group('recency', () {
    test('records when a group was last trained and marks stale ones down', () {
      final s = [_session(14, [('Bench Press', _sets(12, 8, 60))])];
      final chest = _of(_run(s), MuscleGroup.chest);
      expect(chest.daysSinceTrained, 14);
      expect(chest.reason, contains('Last trained 14 days ago'));
    });
  });

  group('pinning and the body scan', () {
    test('a pinned group is a focus area whatever its score', () {
      final s = [for (var w = 0; w < 4; w++) _session(2 + w * 7, [('Bench Press', _sets(12, 8, 60))])];
      final chest = _of(_run(s, pinned: {MuscleGroup.chest}), MuscleGroup.chest);
      expect(chest.level, MuscleLevel.focus);
      expect(chest.pinned, isTrue);
      expect(chest.score, 10);
    });

    test('an unlogged group with a scan score is not untrained', () {
      final calves = _of(_run(const [], scan: {MuscleGroup.calves: 4}), MuscleGroup.calves);
      expect(calves.level, MuscleLevel.focus);
    });

    test('the scan blends into the training score', () {
      final s = [for (var w = 0; w < 4; w++) _session(2 + w * 7, [('Bench Press', _sets(12, 8, 60))])];
      final plain = _of(_run(s), MuscleGroup.chest);
      final scanned = _of(_run(s, scan: {MuscleGroup.chest: 4}), MuscleGroup.chest);
      expect(scanned.score, lessThan(plain.score));
    });
  });
}
