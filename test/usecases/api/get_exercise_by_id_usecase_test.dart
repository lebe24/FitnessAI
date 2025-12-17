import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/api/domain/usecases/get_exercise_by_id_usecase.dart';
import 'package:fitness/app/api/domain/repositories/exercise_repository.dart';
import 'package:fitness/app/api/domain/entities/exercise_entity.dart';
import '../../helpers/test_helpers.dart';

class MockExerciseRepository extends Mock implements ExerciseRepository {}

void main() {
  late GetExerciseByIdUsecase usecase;
  late MockExerciseRepository mockRepository;

  setUp(() {
    mockRepository = MockExerciseRepository();
    usecase = GetExerciseByIdUsecase(mockRepository);
  });

  test('should get exercise by id from repository', () async {
    // arrange
    const exerciseId = 'exercise-1';
    final testExercise = TestFixtures.getTestExercise();
    when(mockRepository.getExerciseById(exerciseId))
        .thenAnswer((_) async => testExercise);

    // act
    final result = await usecase(exerciseId);

    // assert
    expect(result, equals(testExercise));
    verify(mockRepository.getExerciseById(exerciseId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should throw exception when exercise not found', () async {
    // arrange
    const exerciseId = 'non-existent';
    when(mockRepository.getExerciseById(exerciseId))
        .thenThrow(Exception('Exercise not found'));

    // act & assert
    expect(() => usecase(exerciseId), throwsException);
    verify(mockRepository.getExerciseById(exerciseId)).called(1);
  });
}

