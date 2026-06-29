import 'package:dio/dio.dart';
import 'package:fitness/domain/models/profile.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Syncs the user profile to the backend `user_profiles` table.
///
/// IMPORTANT: All other tables (workout_sessions, exercise_logs,
/// nutrition_logs, body_scans, chat_history, workout_plans) have a
/// FK → user_profiles.id. A profile row MUST exist before any other
/// insert, or the DB will reject the row.
///
/// Call [upsertProfile] immediately after every sign-in.
abstract class ProfileRemoteDataSource {
  Future<void> upsertProfile(ProfileEntity profile);
  Future<Map<String, dynamic>?> getProfile();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  late final Dio _dio;

  ProfileRemoteDataSourceImpl() {
    _dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 30),
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

  @override
  Future<void> upsertProfile(ProfileEntity profile) async {
    final body = <String, dynamic>{};
    if (profile.name != null)        body['name']         = profile.name;
    if (profile.email != null)       body['email']        = profile.email;
    if (profile.avatarUrl != null)   body['avatar_url']   = profile.avatarUrl;
    if (profile.gender != null)      body['gender']       = profile.gender;
    if (profile.dob != null)         body['dob']          = profile.dob;
    if (profile.workoutDays != null) body['workout_days'] = profile.workoutDays;
    if (profile.goal != null)        body['goal']         = profile.goal;
    if (profile.experience != null)  body['experience']   = profile.experience;

    // Convert height/weight strings to doubles if present
    if (profile.height != null) {
      final h = double.tryParse(profile.height!.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (h != null) body['height_cm'] = h;
    }
    if (profile.weight != null) {
      final w = double.tryParse(profile.weight!.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (w != null) body['weight_kg'] = w;
    }

    // Always make the request — even an empty body creates the row,
    // which is required for the FK constraints on all other tables.
    await _dio.put('/api/v1/profile', data: body);
  }

  @override
  Future<Map<String, dynamic>?> getProfile() async {
    final res = await _dio.get('/api/v1/profile');
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['exists'] == false) return null;
    return data;
  }
}
