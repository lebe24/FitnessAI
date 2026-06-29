import 'package:dio/dio.dart';
import 'package:fitness/data/models/home/workout_plan_model.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class WorkoutPlanSyncDataSource {
  /// POST /api/v1/plans/saved — returns the cloud-assigned id.
  Future<String> saveToCloud({
    required WorkoutPlanEntity plan,
    String? localImagePath,
  });

  /// GET /api/v1/plans/saved — returns streak from the active plan.
  Future<({int current, int longest})> getStreakFromPlan();
}

class WorkoutPlanSyncDataSourceImpl implements WorkoutPlanSyncDataSource {
  late final Dio _dio;

  WorkoutPlanSyncDataSourceImpl() {
    _dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
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

  @override
  Future<String> saveToCloud({
    required WorkoutPlanEntity plan,
    String? localImagePath,
  }) async {
    final planJson = WorkoutPlanModel.fromEntity(plan).toJson();

    final body = <String, dynamic>{
      'plan_data': planJson,
      'goal': plan.plan.goal,
      'focus': plan.plan.focus,
      'is_active': true,
      if (localImagePath != null) 'image_path': localImagePath,
    };

    final response = await _dio.post('/api/v1/plans/saved', data: body);
    final data = response.data as Map<String, dynamic>;
    return data['id'] as String;
  }

  @override
  Future<({int current, int longest})> getStreakFromPlan() async {
    final response = await _dio.get('/api/v1/plans/saved/streak');
    final data = response.data as Map<String, dynamic>;
    return (
      current: (data['current_streak'] as int?) ?? 0,
      longest: (data['longest_streak'] as int?) ?? 0,
    );
  }
}
