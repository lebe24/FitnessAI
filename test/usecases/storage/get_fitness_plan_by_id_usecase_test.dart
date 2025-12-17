import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/storage/domain/usecases/get_fitness_plan_by_id_usecase.dart';
import 'package:fitness/app/storage/domain/repositories/storage_repository.dart';
import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import '../../helpers/test_helpers.dart';

class MockStorageRepository extends Mock implements StorageRepository {}

void main() {
  late GetFitnessPlanByIdUsecase usecase;
  late MockStorageRepository mockRepository;

  setUp(() {
    mockRepository = MockStorageRepository();
    usecase = GetFitnessPlanByIdUsecase(mockRepository);
  });

  test('should get fitness plan by id from repository', () async {
    // arrange
    const planId = 'plan-1';
    final testPlan = TestFixtures.getTestStoredFitnessPlan();
    when(mockRepository.getFitnessPlanById(planId))
        .thenAnswer((_) async => testPlan);

    // act
    final result = await usecase(planId);

    // assert
    expect(result, equals(testPlan));
    verify(mockRepository.getFitnessPlanById(planId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return null when plan not found', () async {
    // arrange
    const planId = 'non-existent';
    when(mockRepository.getFitnessPlanById(planId))
        .thenAnswer((_) async => null);

    // act
    final result = await usecase(planId);

    // assert
    expect(result, isNull);
    verify(mockRepository.getFitnessPlanById(planId)).called(1);
  });
}

