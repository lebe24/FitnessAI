import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/api/domain/usecases/search_exercises_usecase.dart';
import 'package:fitness/app/api/domain/repositories/exercise_repository.dart';
import 'package:fitness/app/api/domain/entities/exercise_entity.dart';
import '../../helpers/test_helpers.dart';

class MockExerciseRepository extends Mock implements ExerciseRepository {}

void main() {
  late SearchExercisesUsecase usecase;
  late MockExerciseRepository mockRepository;

  setUp(() {
    mockRepository = MockExerciseRepository();
    usecase = SearchExercisesUsecase(mockRepository);
  });

  test('should search exercises and return list of results', () async {
    // arrange
    final testQuery = 'push up';
    final testResults = [
      TestFixtures.getTestExerciseSearchResult(),
      TestFixtures.getTestExerciseSearchResult(),
    ];
    
    when(mockRepository.searchExercises(testQuery))
        .thenAnswer((_) async => testResults);

    // act
    final result = await usecase(testQuery);

    // assert
    expect(result, equals(testResults));
    expect(result.length, equals(2));
    verify(mockRepository.searchExercises(testQuery)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return empty list when no exercises found', () async {
    // arrange
    final testQuery = 'nonexistent exercise';
    when(mockRepository.searchExercises(testQuery))
        .thenAnswer((_) async => []);

    // act
    final result = await usecase(testQuery);

    // assert
    expect(result, isEmpty);
    verify(mockRepository.searchExercises(testQuery)).called(1);
  });

  test('should throw exception when repository throws', () async {
    // arrange
    final testQuery = 'push up';
    when(mockRepository.searchExercises(testQuery))
        .thenThrow(Exception('Search failed'));

    // act & assert
    expect(() => usecase(testQuery), throwsException);
    verify(mockRepository.searchExercises(testQuery)).called(1);
  });
}

