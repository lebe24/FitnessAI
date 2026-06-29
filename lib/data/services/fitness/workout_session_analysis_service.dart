import 'package:dio/dio.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutSessionAnalysisService {
  late final Dio _dio;

  WorkoutSessionAnalysisService() {
    _dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 90),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        handler.next(options);
      },
    ));
  }

  Future<WorkoutSessionAnalysis> analyse({
    required List<Map<String, dynamic>> exercises,
    required int durationMins,
    required int avgRestSecs,
    String? workoutDay,
    String? focus,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/analysis/workout-session',
      data: {
        'exercises': exercises,
        'duration_mins': durationMins,
        'avg_rest_secs': avgRestSecs,
        if (workoutDay != null) 'workout_day': workoutDay,
        if (focus != null) 'focus': focus,
      },
    );
    return WorkoutSessionAnalysis.fromJson(response.data!);
  }
}

class WorkoutSessionAnalysis {
  final String sessionAnalysis;
  final List<String> performanceHighlights;
  final List<String> areasToImprove;
  final String restFeedback;
  final PostWorkoutNutrition nutrition;
  final String nextSessionTip;

  WorkoutSessionAnalysis({
    required this.sessionAnalysis,
    required this.performanceHighlights,
    required this.areasToImprove,
    required this.restFeedback,
    required this.nutrition,
    required this.nextSessionTip,
  });

  factory WorkoutSessionAnalysis.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionAnalysis(
      sessionAnalysis: json['session_analysis'] as String? ?? '',
      performanceHighlights: List<String>.from(json['performance_highlights'] ?? []),
      areasToImprove: List<String>.from(json['areas_to_improve'] ?? []),
      restFeedback: json['rest_feedback'] as String? ?? '',
      nutrition: PostWorkoutNutrition.fromJson(
          json['nutrition_advice'] as Map<String, dynamic>? ?? {}),
      nextSessionTip: json['next_session_tip'] as String? ?? '',
    );
  }
}

class PostWorkoutNutrition {
  final String immediate;
  final int proteinTargetG;
  final List<String> mealSuggestions;
  final String hydration;
  final String timingTip;

  PostWorkoutNutrition({
    required this.immediate,
    required this.proteinTargetG,
    required this.mealSuggestions,
    required this.hydration,
    required this.timingTip,
  });

  factory PostWorkoutNutrition.fromJson(Map<String, dynamic> json) {
    return PostWorkoutNutrition(
      immediate: json['immediate'] as String? ?? '',
      proteinTargetG: (json['protein_target_g'] as num?)?.toInt() ?? 30,
      mealSuggestions: List<String>.from(json['meal_suggestions'] ?? []),
      hydration: json['hydration'] as String? ?? '',
      timingTip: json['timing_tip'] as String? ?? '',
    );
  }
}
