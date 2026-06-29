import 'package:fitness/data/services/api/exercise_remote_service.dart';
import 'package:fitness/domain/models/exercise.dart';
import 'package:fitness/domain/repositories/exercise_repository.dart';

/// Implementation of ExerciseRepository
class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseRemoteDataSource remoteDataSource;

  ExerciseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ExerciseSearchResultEntity>> searchExercises(String query) async {
    final results = await remoteDataSource.searchExercises(query);
    return results;
  }

  @override
  Future<ExerciseEntity> getExerciseById(String exerciseId) async {
    final exercise = await remoteDataSource.getExerciseById(exerciseId);
    return exercise;
  }
}

