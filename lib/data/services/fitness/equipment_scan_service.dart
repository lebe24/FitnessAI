import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fitness/data/models/equipment_scan_model.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

class EquipmentScanService {
  late final Dio _dio;

  EquipmentScanService() {
    _dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
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

  Future<EquipmentScanResult> scanEquipment({
    required File image,
    required String workoutDay,
    required String workoutFocus,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        image.path,
        filename: 'equipment.jpg',
      ),
      'workout_day': workoutDay,
      'workout_focus': workoutFocus,
      'exercises_json': jsonEncode(exercises),
    });

    final response = await _dio.post('/api/v1/equipment/scan', data: formData);
    return EquipmentScanResult.fromJson(response.data as Map<String, dynamic>);
  }
}
