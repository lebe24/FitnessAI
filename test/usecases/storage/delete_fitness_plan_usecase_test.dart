import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/storage/domain/usecases/delete_fitness_plan_usecase.dart';
import 'package:fitness/app/storage/domain/repositories/storage_repository.dart';

class MockStorageRepository extends Mock implements StorageRepository {}

void main() {
  late DeleteFitnessPlanUsecase usecase;
  late MockStorageRepository mockRepository;

  setUp(() {
    mockRepository = MockStorageRepository();
    usecase = DeleteFitnessPlanUsecase(mockRepository);
  });

  test('should delete fitness plan successfully', () async {
    // arrange
    const planId = 'plan-1';
    when(mockRepository.deleteFitnessPlan(planId))
        .thenAnswer((_) async => {});

    // act
    await usecase(planId);

    // assert
    verify(mockRepository.deleteFitnessPlan(planId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should throw exception when deletion fails', () async {
    // arrange
    const planId = 'plan-1';
    when(mockRepository.deleteFitnessPlan(planId))
        .thenThrow(Exception('Delete failed'));

    // act & assert
    expect(() => usecase(planId), throwsException);
    verify(mockRepository.deleteFitnessPlan(planId)).called(1);
  });
}

