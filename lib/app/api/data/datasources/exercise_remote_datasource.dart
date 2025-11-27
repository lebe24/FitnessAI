import 'package:dio/dio.dart';
import 'package:fitness/app/api/data/models/exercise_model.dart';
import 'package:fitness/app/core/constant/constant.dart';

/// Data source interface for ExerciseDB API
abstract class ExerciseRemoteDataSource {
  /// Search exercises by query
  Future<List<ExerciseSearchResultModel>> searchExercises(String query);

  /// Get exercise details by ID
  Future<ExerciseModel> getExerciseById(String exerciseId);
}

class ExerciseRemoteDataSourceImpl implements ExerciseRemoteDataSource {
  late final Dio _dio;

  ExerciseRemoteDataSourceImpl() {
    _dio = Dio(BaseOptions(
      baseUrl: Constant.exerciseDbBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
  }

  @override
  Future<List<ExerciseSearchResultModel>> searchExercises(String query) async {
    try {
      final response = await _dio.get(
        '/api/v1/exercises/search',
        queryParameters: {'query': query},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data
              .map((json) => ExerciseSearchResultModel.fromJson(
                  json as Map<String, dynamic>))
              .toList();
        } else if (data is Map && data.containsKey('data')) {
          final items = data['data'] as List;
          return items
              .map((json) => ExerciseSearchResultModel.fromJson(
                  json as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to search exercises: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to search exercises: ${e.message}');
    } catch (e) {
      throw Exception('Failed to search exercises: $e');
    }
  }

  @override
  Future<ExerciseModel> getExerciseById(String exerciseId) async {
    try {
      final response = await _dio.get('/api/v1/exercises/$exerciseId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return ExerciseModel.fromJson(data);
        } else if (data is Map && data.containsKey('data')) {
          return ExerciseModel.fromJson(data['data'] as Map<String, dynamic>);
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception('Failed to get exercise: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to get exercise: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get exercise: $e');
    }
  }
}

