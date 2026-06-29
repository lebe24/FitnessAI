import 'package:fitness/domain/models/workout_log.dart';

abstract class WorkoutLogRepository {
  Future<WorkoutSessionEntity> createSession({
    required DateTime sessionDate,
    String? dayLabel,
    String? workoutPlanId,
    String? notes,
  });

  Future<List<WorkoutSessionEntity>> listSessions({
    DateTime? fromDate,
    DateTime? toDate,
    int limit,
    int offset,
  });

  Future<WorkoutSessionEntity> getSession(String sessionId);

  Future<WorkoutSessionEntity> completeSession({
    required String sessionId,
    required int durationMins,
  });

  Future<void> deleteSession(String sessionId);

  Future<ExerciseLogEntity> addExerciseLog({
    required String sessionId,
    required ExerciseLogEntity log,
  });

  Future<ExerciseLogEntity> updateExerciseLog({
    required String logId,
    required ExerciseLogEntity log,
  });

  Future<void> deleteExerciseLog(String logId);

  Future<ExerciseProgressEntry> getExerciseProgress(String exerciseName);

  Future<WorkoutStreak> getStreak();
}
