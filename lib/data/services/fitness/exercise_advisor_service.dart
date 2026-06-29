import 'package:dio/dio.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ExerciseVerdict { approved, warning, error }

class ExerciseAdvice {
  final ExerciseVerdict verdict;
  final String message;
  const ExerciseAdvice({required this.verdict, required this.message});
}

class ExerciseAdvisorService {
  late final Dio _dio;

  ExerciseAdvisorService() {
    _dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
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

  Future<ExerciseAdvice> advise({
    required String exerciseName,
    int? sets,
    String? reps,
    String workoutDay = '',
    String workoutFocus = '',
    List<String> existingExercises = const [],
  }) async {
    final response = await _dio.post('/api/v1/exercise/advise', data: {
      'exercise_name': exerciseName,
      if (sets != null) 'sets': sets,
      if (reps != null && reps.isNotEmpty) 'reps': reps,
      'workout_day': workoutDay,
      'workout_focus': workoutFocus,
      'existing_exercises': existingExercises,
    });
    final verdict = response.data['verdict'] == 'approved'
        ? ExerciseVerdict.approved
        : ExerciseVerdict.warning;
    return ExerciseAdvice(
      verdict: verdict,
      message: response.data['message'] as String,
    );
  }
}
