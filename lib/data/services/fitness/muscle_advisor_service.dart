import 'package:dio/dio.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Coaching on one muscle, from the backend.
///
/// The figures come from the client rather than being recomputed server-side,
/// so the advice and the body map cannot disagree about the same training.
/// Mirrors ExerciseAdvisorService: no model or key lives in the app.
class MuscleAdvisorService {
  late final Dio _dio;

  MuscleAdvisorService() {
    _dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      // The backend scales to zero, so the first call of the day waits on a
      // cold start before the model even begins.
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 45),
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

  Future<String> advise({
    required String muscle,
    required double muscleSets,
    required double totalSets,
    required int sessions,
    List<String> exercises = const [],
    List<String> mostTrained = const [],
    List<String> leastTrained = const [],
  }) async {
    final response = await _dio.post('/api/v1/muscle/advise', data: {
      'muscle': muscle,
      'muscle_sets': muscleSets,
      'total_sets': totalSets,
      'sessions': sessions,
      'exercises': exercises,
      'most_trained': mostTrained,
      'least_trained': leastTrained,
    });
    final message = response.data['message'];
    if (message is! String || message.trim().isEmpty) {
      throw Exception('The advisor returned nothing.');
    }
    return message.trim();
  }
}
