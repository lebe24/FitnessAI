import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/storage/domain/usecases/get_all_fitness_plans_usecase.dart';
import 'package:fitness/app/storage/domain/repositories/storage_repository.dart';
import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import '../../helpers/test_helpers.dart';

class MockStorageRepository extends Mock implements StorageRepository {}

void main() {
  late GetAllFitnessPlansUsecase usecase;
  late MockStorageRepository mockRepository;

  setUp(() {
    mockRepository = MockStorageRepository();
    usecase = GetAllFitnessPlansUsecase(mockRepository);
  });

  test('should get all fitness plans from repository', () async {
    // arrange
    final testPlans = [
      TestFixtures.getTestStoredFitnessPlan(),
    ];
    when(mockRepository.getAllFitnessPlans())
        .thenAnswer((_) async => testPlans);

    // act
    final result = await usecase();

    // assert
    expect(result, equals(testPlans));
    expect(result.length, equals(1));
    verify(mockRepository.getAllFitnessPlans()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return empty list when no plans exist', () async {
    // arrange
    when(mockRepository.getAllFitnessPlans())
        .thenAnswer((_) async => []);

    // act
    final result = await usecase();

    // assert
    expect(result, isEmpty);
    verify(mockRepository.getAllFitnessPlans()).called(1);
  });

  test('should throw exception when repository throws', () async {
    // arrange
    when(mockRepository.getAllFitnessPlans())
        .thenThrow(Exception('Failed to get plans'));

    // act & assert
    expect(() => usecase(), throwsException);
    verify(mockRepository.getAllFitnessPlans()).called(1);
  });
}

