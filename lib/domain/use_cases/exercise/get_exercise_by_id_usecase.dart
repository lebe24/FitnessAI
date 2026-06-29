import 'package:fitness/domain/models/exercise.dart';
import 'package:fitness/domain/repositories/exercise_repository.dart';

/// Use case for getting exercise details by ID
class GetExerciseByIdUsecase {
  final ExerciseRepository repository;

  GetExerciseByIdUsecase(this.repository);

  Future<ExerciseEntity> call(String exerciseId) async {
    return await repository.getExerciseById(exerciseId);
  }
}

