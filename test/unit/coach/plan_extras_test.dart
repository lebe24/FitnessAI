import 'package:fitness/data/services/workout_log/workout_draft_storage.dart';
import 'package:fitness/domain/coach/plan_extras.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:flutter_test/flutter_test.dart';

const _push = WorkoutDay(day: 'Monday', focus: 'Push', exercises: [Exercise(name: 'Bench Press', sets: 3, reps: '8')]);
const _pull = WorkoutDay(day: 'Wednesday', focus: 'Pull', exercises: [Exercise(name: 'Row', sets: 3, reps: '8')]);

WorkoutPlanData _plan(List<WorkoutDay> days) => WorkoutPlanData(
      analysisSummary: '',
      physiqueRating: 5,
      goal: 'Build muscle',
      focus: '',
      trainingSplit: 'PPL',
      equipment: const [],
      weeklySplit: WeeklySplit(days: days),
      trainingGuidelines:
          const TrainingGuidelines(restBetweenSets: '', progressiveOverload: '', durationWeeks: ''),
      nutritionGuidelines: const NutritionGuidelines(proteinPerKg: '', calorieSurplus: '', hydration: '', sleep: ''),
      extraTips: const [],
    );

const _fly = Exercise(name: 'Cable Fly', sets: 3, reps: '8-12', targetKg: 15);

void main() {
  test('extras join the matching day only', () {
    final next = withExtraExercises(_plan([_push, _pull]), _push, [_fly])!;
    expect(next.weeklySplit.days[0].exercises.map((e) => e.name), ['Bench Press', 'Cable Fly']);
    expect(next.weeklySplit.days[0].exercises.last.targetKg, 15);
    expect(next.weeklySplit.days[1].exercises, hasLength(1));
  });

  test('an exercise the day already has is not added twice', () {
    final next = withExtraExercises(_plan([_push]), _push, [const Exercise(name: 'bench press', sets: 2, reps: '10'), _fly, _fly])!;
    expect(next.weeklySplit.days.single.exercises, hasLength(2));
  });

  test('a day that is not in the plan changes nothing', () {
    const other = WorkoutDay(day: 'Sunday', focus: 'Legs', exercises: []);
    expect(planDayIndex(_plan([_push]), other), isNull);
    expect(withExtraExercises(_plan([_push]), other, [_fly]), isNull);
  });

  test('two days of the same name need the focus to match', () {
    const am = WorkoutDay(day: 'Monday', focus: 'Push', exercises: []);
    const pm = WorkoutDay(day: 'Monday', focus: 'Pull', exercises: []);
    expect(planDayIndex(_plan([am, pm]), pm), 1);
    const unsure = WorkoutDay(day: 'Monday', focus: 'Legs', exercises: []);
    expect(planDayIndex(_plan([am, pm]), unsure), isNull);
    expect(planDayIndex(_plan([_push]), const WorkoutDay(day: 'monday ', focus: 'Chest', exercises: [])), 0);
  });

  group('the workout draft keeps additions', () {
    test('a draft with only added exercises is worth restoring', () {
      const d = WorkoutDraft(dateKey: '2026-11-26', exercises: [_fly], listChanged: true);
      expect(d.isEmpty, isFalse);
      expect(const WorkoutDraft(dateKey: '2026-11-26', exercises: [_fly]).isEmpty, isTrue);
    });

    test('the target weight and the changed flag survive a restart', () {
      const d = WorkoutDraft(dateKey: '2026-11-26', exercises: [_fly], listChanged: true);
      final back = WorkoutDraft.fromMap(d.toMap());
      expect(back.listChanged, isTrue);
      expect(back.exercises.single.targetKg, 15);
    });

    test('an older draft without the new fields still loads', () {
      final back = WorkoutDraft.fromMap({
        'dateKey': '2026-11-26',
        'exercises': [
          {'name': 'Row', 'sets': 3, 'reps': '8'}
        ],
      });
      expect(back.listChanged, isFalse);
      expect(back.exercises.single.targetKg, isNull);
    });
  });
}
