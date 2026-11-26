import 'package:fitness/data/models/workout_log/workout_log_model.dart';

/// Sessions in the real stored shape, for the history preview and tests: one
/// blob per session where each performed exercise carries
/// `"set 1: 10 reps @ 60kg | set 2: ..."` in `notes`, next to a prescription
/// entry with coaching text and no sets.
class HistorySamples {
  const HistorySamples._();

  static const _names = [
    'Barbell Back Squat',
    'Romanian Deadlift',
    'Leg Press',
    'Walking Lunges',
    'Leg Curl',
    'Calf Raise',
    'Plank',
  ];

  /// A session whose total volume is exactly [totalKg]: three sets of ten per
  /// exercise at whole-kilo weights, with any remainder as one last short set.
  static WorkoutSessionModel session(
    DateTime date,
    String? label, {
    required int minutes,
    required int exercises,
    required int totalKg,
    Map<String, dynamic> feedback = const {},
  }) {
    final units = totalKg ~/ 30;
    final remainder = totalKg - units * 30;
    final base = units ~/ exercises;
    final extra = units % exercises;

    final logs = <Map<String, dynamic>>[];
    for (var i = 0; i < exercises; i++) {
      final w = base + (i < extra ? 1 : 0);
      final name = _names[i % _names.length];
      final sets = [
        for (var s = 1; s <= 3; s++) 'set $s: 10 reps @ ${w}kg',
        if (i == exercises - 1 && remainder > 0) 'set 4: 1 reps @ ${remainder}kg',
      ];
      logs
        ..add({'name': name, 'sets': 3, 'reps': '10', 'notes': 'Keep your chest up and brace.', 'muscle_group': null})
        ..add({'name': name, 'sets': sets.length, 'reps': '10', 'notes': sets.join(' | '), 'muscle_group': null});
    }

    return WorkoutSessionModel(
      sessionDate: DateTime(date.year, date.month, date.day),
      dayLabel: label,
      durationMins: minutes,
      isCompleted: true,
      workoutLogs: logs,
      feedback: feedback,
    );
  }

  static const feedback = <String, dynamic>{
    'session_analysis': 'A solid leg day. Your squat moved well and the volume is up on last week.',
    'performance_highlights': ['Squat reps stayed clean across all three sets', 'Leg press up 10 kg on last week'],
    'areas_to_improve': ['Rest between squat sets was short', 'Calves got the least work'],
    'rest_feedback': 'Aim for about 2 minutes between heavy sets.',
    'next_session_tip': 'Add one set of calf raises and keep the squat weight the same.',
    'nutrition_advice': {
      'immediate': 'Have a meal with protein and carbs within the hour.',
      'protein_target_g': 35,
      'meal_suggestions': ['Chicken and rice', 'Greek yoghurt and fruit'],
      'hydration': 'Drink about 500 ml over the next hour.',
      'timing_tip': 'Eat again within two hours.',
    },
  };

  /// Newest first is not required; the page sorts.
  static List<WorkoutSessionModel> get all => [
        session(DateTime(2025, 11, 20), 'Legs & Core', minutes: 58, exercises: 7, totalKg: 9420, feedback: feedback),
        session(DateTime(2025, 11, 18), 'Back & Biceps', minutes: 52, exercises: 6, totalKg: 7860),
        session(DateTime(2025, 11, 17), 'Chest & Triceps', minutes: 61, exercises: 6, totalKg: 8340),
        session(DateTime(2025, 11, 14), 'Shoulders & Arms', minutes: 47, exercises: 6, totalKg: 5980),
        session(DateTime(2025, 10, 30), 'Legs & Core', minutes: 55, exercises: 7, totalKg: 9060),
        session(DateTime(2025, 10, 28), 'Back & Biceps', minutes: 50, exercises: 6, totalKg: 7410),
        session(DateTime(2025, 10, 14), 'Chest & Triceps', minutes: 58, exercises: 6, totalKg: 7980),
        session(DateTime(2025, 9, 22), 'Wednesday', minutes: 0, exercises: 5, totalKg: 6300),
        session(DateTime(2025, 9, 9), null, minutes: 44, exercises: 5, totalKg: 5400),
        session(DateTime(2025, 8, 19), 'Legs & Core', minutes: 49, exercises: 6, totalKg: 7200),
        session(DateTime(2025, 8, 5), 'Back & Biceps', minutes: 46, exercises: 6, totalKg: 6600),
        session(DateTime(2025, 7, 21), 'Chest & Triceps', minutes: 51, exercises: 6, totalKg: 6900),
      ];
}
