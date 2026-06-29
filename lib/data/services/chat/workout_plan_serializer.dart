import 'package:fitness/domain/models/workout_plan.dart';

/// Helper class to serialize workout plan data to JSON for backend communication
class WorkoutPlanSerializer {
  /// Convert WorkoutDay to JSON format for sending to backend
  static Map<String, dynamic> workoutDayToJson(WorkoutDay workoutDay) {
    return {
      'day': workoutDay.day,
      'focus': workoutDay.focus,
      'exercises': workoutDay.exercises.map((exercise) => {
        'name': exercise.name,
        'sets': exercise.sets,
        'reps': exercise.reps,
        if (exercise.notes != null) 'notes': exercise.notes,
      }).toList(),
      if (workoutDay.tip != null) 'tip': workoutDay.tip,
    };
  }
}

