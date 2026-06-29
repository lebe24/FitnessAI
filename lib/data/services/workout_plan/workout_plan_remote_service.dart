import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:fitness/ui/core/constants/constant.dart';

/// Thrown when the workout-plan endpoint returns an unexpected response.
class WorkoutPlanNetworkException implements Exception {
  final String message;
  final int? statusCode;
  const WorkoutPlanNetworkException(this.message, {this.statusCode});

  @override
  String toString() => statusCode != null
      ? 'WorkoutPlanNetworkException [$statusCode]: $message'
      : 'WorkoutPlanNetworkException: $message';
}

/// Pure HTTP client for the /api/v1/plans/workout endpoint.
///
/// Responsibilities:
///   - Send the multipart request.
///   - Return the raw decoded JSON as `Map<String, dynamic>`.
///   - Throw [WorkoutPlanNetworkException] on any HTTP or network failure.
///
/// Model conversion and domain validation are the repository's responsibility.
/// This class does NOT import any model or domain type.
class WorkoutPlanRemoteDataSource {
  final Dio _dio;

  /// Accepts an optional [baseUrl] so the class can be unit-tested without
  /// touching real network I/O or `Constant`.
  WorkoutPlanRemoteDataSource({String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? Constant.backendUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 2),
        ));

  /// POST /api/v1/plans/workout
  ///
  /// Returns the raw response body as a [Map].
  /// Throws [WorkoutPlanNetworkException] on failure.
  Future<Map<String, dynamic>> generateWorkoutPlan({
    required File image,
    required String goal,
    required String duration,
    required String trainingSplit,
    required String gender,
    required String height,
    required String weight,
    required String experience,
    String? extraInfo,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        image.path,
        filename: image.path.split('/').last,
      ),
      'goal': goal,
      'duration': duration,
      'training_split': trainingSplit,
      'gender': gender,
      'height': height,
      'weight': weight,
      'experience': experience,
      'extra_info': extraInfo ?? '',
    });

    try {
      final response = await _dio.post(
        '/api/v1/plans/workout',
        data: formData,
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        if (response.data is String) {
          return jsonDecode(response.data as String) as Map<String, dynamic>;
        }
        throw WorkoutPlanNetworkException(
          'Unexpected response type: ${response.data.runtimeType}',
          statusCode: response.statusCode,
        );
      }

      throw WorkoutPlanNetworkException(
        response.statusMessage ?? 'Request failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      final detail = body is Map ? body['detail'] ?? body['error'] : null;
      throw WorkoutPlanNetworkException(
        detail?.toString() ?? e.message ?? 'Network error',
        statusCode: code,
      );
    } on WorkoutPlanNetworkException {
      rethrow;
    } catch (e) {
      throw WorkoutPlanNetworkException('Unexpected error: $e');
    }
  }

  /// GET /  — used for health/base info checks.
  Future<String> getBaseInfo() async {
    try {
      final response = await _dio.get('/');
      if (response.statusCode == 200) return response.data.toString();
      throw WorkoutPlanNetworkException(
        response.statusMessage ?? 'Request failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw WorkoutPlanNetworkException(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
