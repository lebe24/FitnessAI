import 'package:fitness/domain/models/exercise.dart';

/// Repository interface for ExerciseDB API
abstract class ExerciseRepository {
  /// Search exercises by name/query
  /// Returns a list of exercise search results
  Future<List<ExerciseSearchResultEntity>> searchExercises(String query);

  /// Get exercise details by ID
  /// Returns full exercise details
  Future<ExerciseEntity> getExerciseById(String exerciseId);
}

