import 'package:dio/dio.dart';
import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for workout session & exercise log endpoints.
///
/// Every request sends the Supabase JWT in Authorization header so FastAPI
/// can validate and extract user_id server-side.
abstract class WorkoutLogRemoteDataSource {
  Future<WorkoutSessionModel> createSession({
    required DateTime sessionDate,
    String? dayLabel,
    String? workoutPlanId,
    String? notes,
  });

  Future<List<WorkoutSessionModel>> listSessions({
    DateTime? fromDate,
    DateTime? toDate,
    int limit,
    int offset,
  });

  Future<WorkoutSessionModel> getSession(String sessionId);

  Future<WorkoutSessionModel> completeSession({
    required String sessionId,
    required int durationMins,
  });

  Future<void> deleteSession(String sessionId);

  Future<ExerciseLogModel> addExerciseLog({
    required String sessionId,
    required ExerciseLogModel log,
  });

  Future<ExerciseLogModel> updateExerciseLog({
    required String logId,
    required ExerciseLogModel log,
  });

  Future<void> deleteExerciseLog(String logId);

  Future<List<ExerciseLogModel>> getExerciseProgress(String exerciseName);

  Future<WorkoutStreakModel> getStreak();

  /// Save a complete session (metadata + all exercises) as a single DB row.
  Future<WorkoutSessionModel> saveCompleteSession({
    required DateTime sessionDate,
    required List<Exercise> exercises,
    String? dayLabel,
    String? workoutPlanId,
    int durationMins,
    String? notes,
  });

  /// Patch the feedback field on an existing session.
  Future<void> saveFeedback({
    required String sessionId,
    required Map<String, dynamic> feedback,
  });
}

class WorkoutLogRemoteDataSourceImpl implements WorkoutLogRemoteDataSource {
  late final Dio _dio;

  WorkoutLogRemoteDataSourceImpl() {
    _dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 2),
    ));

    // Inject Supabase JWT on every request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
    ));
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<WorkoutSessionModel> createSession({
    required DateTime sessionDate,
    String? dayLabel,
    String? workoutPlanId,
    String? notes,
  }) async {
    final res = await _dio.post('/api/v1/logs/sessions', data: {
      'session_date': _dateStr(sessionDate),
      if (dayLabel != null) 'day_label': dayLabel,
      if (workoutPlanId != null) 'workout_plan_id': workoutPlanId,
      if (notes != null) 'notes': notes,
    });
    return WorkoutSessionModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<WorkoutSessionModel>> listSessions({
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _dio.get('/api/v1/logs/sessions', queryParameters: {
      if (fromDate != null) 'from_date': _dateStr(fromDate),
      if (toDate != null) 'to_date': _dateStr(toDate),
      'limit': limit,
      'offset': offset,
    });
    final data = res.data as Map<String, dynamic>;
    return (data['sessions'] as List)
        .map((s) => WorkoutSessionModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WorkoutSessionModel> getSession(String sessionId) async {
    final res = await _dio.get('/api/v1/logs/sessions/$sessionId');
    return WorkoutSessionModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<WorkoutSessionModel> completeSession({
    required String sessionId,
    required int durationMins,
  }) async {
    final res = await _dio.patch('/api/v1/logs/sessions/$sessionId', data: {
      'is_completed': true,
      'duration_mins': durationMins,
    });
    return WorkoutSessionModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _dio.delete('/api/v1/logs/sessions/$sessionId');
  }

  @override
  Future<ExerciseLogModel> addExerciseLog({
    required String sessionId,
    required ExerciseLogModel log,
  }) async {
    final res = await _dio.post(
      '/api/v1/logs/sessions/$sessionId/exercises',
      data: log.toJson(),
    );
    return ExerciseLogModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<ExerciseLogModel> updateExerciseLog({
    required String logId,
    required ExerciseLogModel log,
  }) async {
    final res = await _dio.patch(
      '/api/v1/logs/exercises/$logId',
      data: log.toJson(),
    );
    return ExerciseLogModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteExerciseLog(String logId) async {
    await _dio.delete('/api/v1/logs/exercises/$logId');
  }

  @override
  Future<List<ExerciseLogModel>> getExerciseProgress(
      String exerciseName) async {
    final res = await _dio.get('/api/v1/logs/progress/$exerciseName');
    final data = res.data as Map<String, dynamic>;
    return (data['history'] as List)
        .map((e) => ExerciseLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WorkoutStreakModel> getStreak() async {
    final res = await _dio.get('/api/v1/logs/streak');
    return WorkoutStreakModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<WorkoutSessionModel> saveCompleteSession({
    required DateTime sessionDate,
    required List<Exercise> exercises,
    String? dayLabel,
    String? workoutPlanId,
    int durationMins = 0,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'session_date': _dateStr(sessionDate),
      'duration_mins': durationMins,
      'workout_logs': exercises
          .asMap()
          .entries
          .map((e) => ExerciseEntryModel(
                name: e.value.name,
                sets: e.value.sets,
                reps: e.value.reps,
                notes: e.value.notes,
                orderIndex: e.key,
              ).toJson())
          .toList(),
      if (dayLabel != null) 'day_label': dayLabel,
      if (workoutPlanId != null) 'workout_plan_id': workoutPlanId,
      if (notes != null) 'notes': notes,
    };
    final res = await _dio.post('/api/v1/logs/sessions/complete', data: body);
    return WorkoutSessionModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> saveFeedback({
    required String sessionId,
    required Map<String, dynamic> feedback,
  }) async {
    await _dio.patch(
      '/api/v1/logs/sessions/$sessionId',
      data: {'feedback': feedback},
    );
  }
}
