import 'package:fitness/domain/models/workout_log.dart';
import 'package:fitness/domain/repositories/workout_log_repository.dart';

class FakeWorkoutLogRepository implements WorkoutLogRepository {
  Exception? createSessionError;
  Exception? addExerciseLogError;

  bool completeSessionCalled = false;
  bool addExerciseLogCalled = false;
  String? lastAddSessionId;
  ExerciseLogEntity? lastAddLog;

  final _kDate = DateTime(2025, 6, 15);

  @override
  Future<WorkoutSessionEntity> createSession({
    required DateTime sessionDate,
    String? dayLabel,
    String? workoutPlanId,
    String? notes,
  }) async {
    if (createSessionError != null) throw createSessionError!;
    return WorkoutSessionEntity(
      id: 'sess-001',
      sessionDate: sessionDate,
      dayLabel: dayLabel,
      isCompleted: false,
    );
  }

  @override
  Future<WorkoutSessionEntity> completeSession({
    required String sessionId,
    required int durationMins,
  }) async {
    completeSessionCalled = true;
    return WorkoutSessionEntity(
      id: sessionId,
      sessionDate: _kDate,
      isCompleted: true,
      durationMins: durationMins,
    );
  }

  @override
  Future<List<WorkoutSessionEntity>> listSessions({
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 20,
    int offset = 0,
  }) async =>
      [
        WorkoutSessionEntity(id: 'sess-001', sessionDate: _kDate),
        WorkoutSessionEntity(id: 'sess-002', sessionDate: _kDate),
      ];

  @override
  Future<WorkoutSessionEntity> getSession(String sessionId) async =>
      WorkoutSessionEntity(id: sessionId, sessionDate: _kDate);

  @override
  Future<void> deleteSession(String sessionId) async {}

  @override
  Future<ExerciseLogEntity> addExerciseLog({
    required String sessionId,
    required ExerciseLogEntity log,
  }) async {
    if (addExerciseLogError != null) throw addExerciseLogError!;
    addExerciseLogCalled = true;
    lastAddSessionId = sessionId;
    lastAddLog = log;
    return ExerciseLogEntity(
      id: 'log-001',
      sessionId: sessionId,
      exerciseName: log.exerciseName,
      muscleGroup: log.muscleGroup,
      equipment: log.equipment,
      orderIndex: log.orderIndex,
      sets: log.sets,
      notes: log.notes,
    );
  }

  @override
  Future<ExerciseLogEntity> updateExerciseLog({
    required String logId,
    required ExerciseLogEntity log,
  }) async =>
      ExerciseLogEntity(
        id: logId,
        sessionId: log.sessionId,
        exerciseName: log.exerciseName,
        sets: log.sets,
        notes: 'updated',
      );

  @override
  Future<void> deleteExerciseLog(String logId) async {}

  @override
  Future<ExerciseProgressEntry> getExerciseProgress(String exerciseName) async =>
      ExerciseProgressEntry(exerciseName: exerciseName, history: []);

  @override
  Future<WorkoutStreak> getStreak() async => const WorkoutStreak(
        currentStreak: 3,
        longestStreak: 7,
        lastSession: '2025-06-15',
      );
}
