import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPlanService {
  late final Dio _dio;

  ChatPlanService() {
    _dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
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

  /// POST /api/v1/plans/from-chat
  ///
  /// Converts a chat transcript into a structured [WorkoutPlanEntity].
  /// Returns the raw response map — validated + converted by the repository layer.
  Future<Map<String, dynamic>> generateFromChat({
    required String conversation,
    String goal            = '',
    String gender          = '',
    String height          = '',
    String weight          = '',
    String experience      = '',
    String duration        = '',
    String trainingSplit   = '',
    String extraInfo       = '',
  }) async {
    final response = await _dio.post<dynamic>(
      '/api/v1/plans/from-chat',
      data: {
        'conversation':   conversation,
        'goal':           goal,
        'gender':         gender,
        'height':         height,
        'weight':         weight,
        'experience':     experience,
        'duration':       duration,
        'training_split': trainingSplit,
        'extra_info':     extraInfo,
      },
    );

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    if (response.data is String) {
      return jsonDecode(response.data as String) as Map<String, dynamic>;
    }
    throw Exception('Unexpected response type: ${response.data.runtimeType}');
  }
}
