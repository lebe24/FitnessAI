import 'package:fitness/data/models/workout_log/workout_log_model.dart';

final coachNow = DateTime(2026, 11, 26, 10);

/// A logged session [daysAgo] days before [coachNow], one entry per exercise.
WorkoutSessionModel logged(int daysAgo, Map<String, List<(int reps, num kg)>> exercises) => WorkoutSessionModel(
      sessionDate: DateTime(2026, 11, 26).subtract(Duration(days: daysAgo)),
      workoutLogs: [
        for (final e in exercises.entries)
          {
            'name': e.key,
            'notes': [
              for (var i = 0; i < e.value.length; i++) 'set ${i + 1}: ${e.value[i].$1} reps @ ${e.value[i].$2}kg'
            ].join(' | '),
          }
      ],
    );

List<(int, num)> sets(int n, int reps, num kg) => [for (var i = 0; i < n; i++) (reps, kg)];
