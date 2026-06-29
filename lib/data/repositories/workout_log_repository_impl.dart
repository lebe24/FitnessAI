import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/workout_log/workout_log_remote_service.dart';
import 'package:fitness/domain/models/workout_log.dart';
import 'package:fitness/domain/repositories/workout_log_repository.dart';

class WorkoutLogRepositoryImpl implements WorkoutLogRepository {
  final WorkoutLogRemoteDataSource _remote;

  WorkoutLogRepositoryImpl(this._remote);

  @override
  Future<WorkoutSessionEntity> createSession({
    required DateTime sessionDate,
    String? dayLabel,
    String? workoutPlanId,
    String? notes,
  }) =>
      _remote.createSession(
        sessionDate: sessionDate,
        dayLabel: dayLabel,
        workoutPlanId: workoutPlanId,
        notes: notes,
      );

  @override
  Future<List<WorkoutSessionEntity>> listSessions({
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 20,
    int offset = 0,
  }) =>
      _remote.listSessions(
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
        offset: offset,
      );

  @override
  Future<WorkoutSessionEntity> getSession(String sessionId) =>
      _remote.getSession(sessionId);

  @override
  Future<WorkoutSessionEntity> completeSession({
    required String sessionId,
    required int durationMins,
  }) =>
      _remote.completeSession(
        sessionId: sessionId,
        durationMins: durationMins,
      );

  @override
  Future<void> deleteSession(String sessionId) =>
      _remote.deleteSession(sessionId);

  @override
  Future<ExerciseLogEntity> addExerciseLog({
    required String sessionId,
    required ExerciseLogEntity log,
  }) =>
      _remote.addExerciseLog(
        sessionId: sessionId,
        log: ExerciseLogModel(
          exerciseName: log.exerciseName,
          muscleGroup: log.muscleGroup,
          equipment: log.equipment,
          orderIndex: log.orderIndex,
          sets: log.sets
              .map((s) => SetEntryModel(
                    setNumber: s.setNumber,
                    reps: s.reps,
                    weightKg: s.weightKg,
                    completed: s.completed,
                    rpe: s.rpe,
                    notes: s.notes,
                  ))
              .toList(),
          notes: log.notes,
        ),
      );

  @override
  Future<ExerciseLogEntity> updateExerciseLog({
    required String logId,
    required ExerciseLogEntity log,
  }) =>
      _remote.updateExerciseLog(
        logId: logId,
        log: ExerciseLogModel(
          exerciseName: log.exerciseName,
          muscleGroup: log.muscleGroup,
          equipment: log.equipment,
          orderIndex: log.orderIndex,
          sets: log.sets
              .map((s) => SetEntryModel(
                    setNumber: s.setNumber,
                    reps: s.reps,
                    weightKg: s.weightKg,
                    completed: s.completed,
                    rpe: s.rpe,
                    notes: s.notes,
                  ))
              .toList(),
          notes: log.notes,
        ),
      );

  @override
  Future<void> deleteExerciseLog(String logId) =>
      _remote.deleteExerciseLog(logId);

  @override
  Future<ExerciseProgressEntry> getExerciseProgress(
      String exerciseName) async {
    final history = await _remote.getExerciseProgress(exerciseName);
    return ExerciseProgressEntry(
      exerciseName: exerciseName,
      history: history,
    );
  }

  @override
  Future<WorkoutStreak> getStreak() => _remote.getStreak();
}
