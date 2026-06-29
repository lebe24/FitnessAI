import 'package:fitness/domain/models/exercise.dart';
import 'package:fitness/domain/repositories/exercise_repository.dart';
import '../fixtures/fixtures.dart';

class FakeExerciseRepository implements ExerciseRepository {
  List<ExerciseSearchResultEntity> searchResult = [Fixtures.exerciseResult()];
  ExerciseEntity exerciseDetail = Fixtures.exercise();
  Exception? searchError;
  Exception? getByIdError;
  String? lastSearchQuery;
  String? lastGetByIdArg;

  @override
  Future<List<ExerciseSearchResultEntity>> searchExercises(String query) async {
    if (searchError != null) throw searchError!;
    lastSearchQuery = query;
    return searchResult;
  }

  @override
  Future<ExerciseEntity> getExerciseById(String exerciseId) async {
    if (getByIdError != null) throw getByIdError!;
    lastGetByIdArg = exerciseId;
    return exerciseDetail;
  }
}
