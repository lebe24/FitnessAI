import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/storage/domain/usecases/save_fitness_plan_usecase.dart';
import 'package:fitness/app/storage/domain/repositories/storage_repository.dart';
import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';
import '../../helpers/test_helpers.dart';

class MockStorageRepository extends Mock implements StorageRepository {}

void main() {
  late SaveFitnessPlanUsecase usecase;
  late MockStorageRepository mockRepository;

  setUp(() {
    mockRepository = MockStorageRepository();
    usecase = SaveFitnessPlanUsecase(mockRepository);
  });

  test('should save fitness plan successfully', () async {
    // arrange
    final testWorkoutPlan = TestFixtures.getTestWorkoutPlan();
    final testStoredPlan = TestFixtures.getTestStoredFitnessPlan();
    
    when(mockRepository.saveFitnessPlan(
      workoutPlan: anyNamed('workoutPlan'),
      imageFilePath: anyNamed('imageFilePath'),
    )).thenAnswer((_) async => testStoredPlan);

    // act
    final result = await usecase(
      workoutPlan: testWorkoutPlan,
      imageFilePath: '/path/to/image.jpg',
    );

    // assert
    expect(result, equals(testStoredPlan));
    verify(mockRepository.saveFitnessPlan(
      workoutPlan: testWorkoutPlan,
      imageFilePath: '/path/to/image.jpg',
    )).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should save fitness plan without image', () async {
    // arrange
    final testWorkoutPlan = TestFixtures.getTestWorkoutPlan();
    final testStoredPlan = TestFixtures.getTestStoredFitnessPlan();
    
    when(mockRepository.saveFitnessPlan(
      workoutPlan: anyNamed('workoutPlan'),
      imageFilePath: anyNamed('imageFilePath'),
    )).thenAnswer((_) async => testStoredPlan);

    // act
    final result = await usecase(
      workoutPlan: testWorkoutPlan,
    );

    // assert
    expect(result, equals(testStoredPlan));
    verify(mockRepository.saveFitnessPlan(
      workoutPlan: testWorkoutPlan,
      imageFilePath: null,
    )).called(1);
  });

  test('should throw exception when repository throws', () async {
    // arrange
    final testWorkoutPlan = TestFixtures.getTestWorkoutPlan();
    when(mockRepository.saveFitnessPlan(
      workoutPlan: anyNamed('workoutPlan'),
      imageFilePath: anyNamed('imageFilePath'),
    )).thenThrow(Exception('Save failed'));

    // act & assert
    expect(
      () => usecase(workoutPlan: testWorkoutPlan),
      throwsException,
    );
    verify(mockRepository.saveFitnessPlan(
      workoutPlan: testWorkoutPlan,
      imageFilePath: null,
    )).called(1);
  });
}

