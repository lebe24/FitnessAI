import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/api/data/repositories/exercise_repository_impl.dart';
import 'package:fitness/app/api/data/datasources/exercise_remote_datasource.dart';
import 'package:fitness/app/api/domain/entities/exercise_entity.dart';
import '../helpers/test_helpers.dart';

class MockExerciseRemoteDataSource extends Mock implements ExerciseRemoteDataSource {}

void main() {
  late ExerciseRepositoryImpl repository;
  late MockExerciseRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockExerciseRemoteDataSource();
    repository = ExerciseRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
    );
  });

  group('searchExercises', () {
    test('should return list of exercise search results', () async {
      // arrange
      const query = 'push up';
      final testResults = [
        TestFixtures.getTestExerciseSearchResult(),
      ];
      when(mockRemoteDataSource.searchExercises(query))
          .thenAnswer((_) async => testResults);

      // act
      final result = await repository.searchExercises(query);

      // assert
      expect(result, equals(testResults));
      expect(result.length, equals(1));
      verify(mockRemoteDataSource.searchExercises(query)).called(1);
    });

    test('should return empty list when no results found', () async {
      // arrange
      const query = 'nonexistent';
      when(mockRemoteDataSource.searchExercises(query))
          .thenAnswer((_) async => []);

      // act
      final result = await repository.searchExercises(query);

      // assert
      expect(result, isEmpty);
      verify(mockRemoteDataSource.searchExercises(query)).called(1);
    });
  });

  group('getExerciseById', () {
    test('should return exercise entity by id', () async {
      // arrange
      const exerciseId = 'exercise-1';
      final testExercise = TestFixtures.getTestExercise();
      when(mockRemoteDataSource.getExerciseById(exerciseId))
          .thenAnswer((_) async => testExercise);

      // act
      final result = await repository.getExerciseById(exerciseId);

      // assert
      expect(result, equals(testExercise));
      verify(mockRemoteDataSource.getExerciseById(exerciseId)).called(1);
    });

    test('should throw exception when exercise not found', () async {
      // arrange
      const exerciseId = 'non-existent';
      when(mockRemoteDataSource.getExerciseById(exerciseId))
          .thenThrow(Exception('Exercise not found'));

      // act & assert
      expect(
        () => repository.getExerciseById(exerciseId),
        throwsException,
      );
    });
  });
}

