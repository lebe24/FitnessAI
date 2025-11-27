import 'package:fitness/app/api/domain/entities/exercise_entity.dart';
import 'package:fitness/app/api/domain/repositories/exercise_repository.dart';

/// Use case for searching exercises by name
class SearchExercisesUsecase {
  final ExerciseRepository repository;

  SearchExercisesUsecase(this.repository);

  Future<List<ExerciseSearchResultEntity>> call(String query) async {
    return await repository.searchExercises(query);
  }
}

