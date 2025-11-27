import 'package:fitness/app/api/data/datasources/exercise_remote_datasource.dart';
import 'package:fitness/app/api/domain/entities/exercise_entity.dart';
import 'package:fitness/app/api/domain/repositories/exercise_repository.dart';

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

