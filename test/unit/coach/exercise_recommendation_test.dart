import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/coach/exercise_recommendation.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/progression/progression_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'coach_fixtures.dart';

const _bench = Exercise(name: 'Bench Press', sets: 3, reps: '8-10', targetKg: 60);

ExerciseRecommendation _rec(
  Exercise ex,
  List<WorkoutSessionModel> sessions, {
  GoalKind goal = GoalKind.hypertrophy,
  bool beginner = false,
}) =>
    ExerciseRecommendation.of(
      exercise: ex,
      history: ExerciseHistory.fromSessions(sessions, ex.name),
      goal: goal,
      now: coachNow,
      beginner: beginner,
    );

void main() {
  test('with nothing logged it says how to find a weight, using the plan target', () {
    final r = _rec(_bench, []);
    expect(r.action, CoachAction.findWeight);
    expect(r.target.weightKg, 60);
    expect(r.reason, contains('No sets logged yet'));
  });

  test('with nothing logged and no target it gives no weight', () {
    final r = _rec(const Exercise(name: 'Bench Press', sets: 3, reps: '8-10'), []);
    expect(r.target.weightKg, isNull);
    expect(r.reason, contains('2 more times'));
  });

  test('top of the range on enough sessions adds weight, like the weekly update', () {
    final r = _rec(_bench, [logged(3, {'Bench Press': sets(3, 10, 60)}), logged(10, {'Bench Press': sets(3, 10, 60)})]);
    expect(r.action, CoachAction.addWeight);
    expect(r.target.weightKg, 62.5);
    expect(r.badge, '+2.5 kg');
  });

  test('a missed set holds', () {
    final r = _rec(_bench, [
      logged(3, {'Bench Press': [(10, 60), (6, 60), (6, 60)]}),
    ]);
    expect(r.action, CoachAction.hold);
    expect(r.target.weightKg, 60);
  });

  test('a good session that is not yet enough to progress also holds', () {
    final r = _rec(_bench, [logged(3, {'Bench Press': sets(3, 9, 60)})]);
    expect(r.action, CoachAction.hold);
  });

  test('after more than six weeks away it eases back about ten percent', () {
    final r = _rec(_bench, [logged(60, {'Bench Press': sets(3, 10, 60)})]);
    expect(r.action, CoachAction.easeOff);
    expect(r.target.weightKg, 54);
    expect(r.reason, contains('over 6 weeks'));
  });

  test('a timed set is not judged by reps', () {
    final r = _rec(const Exercise(name: 'Plank', sets: 3, reps: '45 sec'), [logged(2, {'Plank': [(1, 0)]})]);
    expect(r.action, CoachAction.timed);
    expect(r.target.reps, '45 sec');
    expect(r.alternative, isNull);
  });

  group('goal rep range', () {
    test('ranges by goal', () {
      expect(RepRange.forGoal(GoalKind.strength).label, '3–6');
      expect(RepRange.forGoal(GoalKind.hypertrophy).label, '6–12');
      expect(RepRange.forGoal(GoalKind.fatLoss).label, '12–15');
      expect(RepRange.forGoal(GoalKind.general).label, '8–12');
    });

    test('no second option when the plan already sits in the range', () {
      final r = _rec(_bench, [logged(3, {'Bench Press': sets(3, 10, 60)})]);
      expect(r.alternative, isNull);
    });

    test('high reps for a muscle goal offers fewer reps with more weight', () {
      final r = _rec(
        const Exercise(name: 'Bench Press', sets: 4, reps: '15-20'),
        [logged(3, {'Bench Press': sets(4, 16, 40)})],
      );
      expect(r.alternative!.reps, '10');
      expect(r.alternative!.weightKg, greaterThan(40));
      expect(r.alternative!.weightKg, lessThanOrEqualTo(44)); // never more than +10%
      expect(r.alternativeReason, contains('muscle growth'));
    });

    test('low reps for a fat loss goal offers more reps, no more than 10% lighter', () {
      final r = _rec(
        const Exercise(name: 'Bench Press', sets: 3, reps: '5'),
        [logged(3, {'Bench Press': sets(3, 5, 80)})],
        goal: GoalKind.fatLoss,
      );
      expect(r.alternative!.reps, '12');
      expect(r.alternative!.weightKg, 72);
    });

    test('a beginner is never offered heavy low-rep work', () {
      final r = _rec(
        const Exercise(name: 'Bench Press', sets: 3, reps: '10-12'),
        [logged(3, {'Bench Press': sets(3, 12, 40)})],
        goal: GoalKind.strength,
        beginner: true,
      );
      expect(r.alternative, isNull);
    });

    test('an experienced lifter after strength is offered it', () {
      final r = _rec(
        const Exercise(name: 'Bench Press', sets: 3, reps: '10-12'),
        [logged(3, {'Bench Press': sets(3, 12, 40)})],
        goal: GoalKind.strength,
      );
      expect(r.alternative!.reps, '5');
    });

    test('nothing to base a second option on without history', () {
      expect(_rec(const Exercise(name: 'Bench Press', sets: 3, reps: '20'), []).alternative, isNull);
    });
  });

  test('a prescription reads like a gym note', () {
    expect(const SetPrescription(weightKg: 62.5, sets: 3, reps: '8-10').label, '3 × 8-10 @ 62.5 kg');
    expect(const SetPrescription(sets: 3, reps: '12').label, '3 × 12');
  });
}
