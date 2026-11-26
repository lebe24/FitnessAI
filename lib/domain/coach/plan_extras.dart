import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/progression/progression_engine.dart';

/// Where [day] sits in [plan]'s week, or null when it is not one of its days.
///
/// Matched by day name and focus; a name alone is enough only if the plan has
/// one day of that name, so extras never land on the wrong session.
int? planDayIndex(WorkoutPlanData plan, WorkoutDay day) {
  String norm(String s) => s.trim().toLowerCase();
  final days = plan.weeklySplit.days;
  for (var i = 0; i < days.length; i++) {
    if (norm(days[i].day) == norm(day.day) && norm(days[i].focus) == norm(day.focus)) return i;
  }
  final byName = [
    for (var i = 0; i < days.length; i++)
      if (norm(days[i].day) == norm(day.day)) i
  ];
  return byName.length == 1 ? byName.single : null;
}

/// [plan] with [added] at the end of [day], leaving out any it already has.
/// Null when [day] is not part of the plan.
WorkoutPlanData? withExtraExercises(WorkoutPlanData plan, WorkoutDay day, List<Exercise> added) {
  final index = planDayIndex(plan, day);
  if (index == null) return null;
  final target = plan.weeklySplit.days[index];
  final have = {for (final e in target.exercises) ExerciseHistory.keyFor(e.name)};
  final fresh = [
    for (final e in added)
      if (have.add(ExerciseHistory.keyFor(e.name))) e
  ];
  final days = [...plan.weeklySplit.days];
  days[index] = WorkoutDay(
    day: target.day,
    focus: target.focus,
    exercises: [...target.exercises, ...fresh],
    tip: target.tip,
  );
  return ProgressionEngine.withSplit(plan, WeeklySplit(days: days));
}
