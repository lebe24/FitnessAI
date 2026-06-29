import 'package:fitness/domain/models/exercise.dart';
import 'package:fitness/domain/repositories/exercise_repository.dart';

/// Use case for searching exercises by name
class SearchExercisesUsecase {
  final ExerciseRepository repository;

  SearchExercisesUsecase(this.repository);

  Future<List<ExerciseSearchResultEntity>> call(String query) async {
    return await repository.searchExercises(query);
  }
}

