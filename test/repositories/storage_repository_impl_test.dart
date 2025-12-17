import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/storage/data/repositories/storage_repository_impl.dart';
import 'package:fitness/app/storage/data/datasources/local_storage_datasource.dart';
import 'package:fitness/app/storage/data/datasources/file_storage_datasource.dart';
import 'package:fitness/app/storage/data/models/stored_fitness_plan_model.dart';
import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';
import '../helpers/test_helpers.dart';

class MockLocalStorageDataSource extends Mock implements LocalStorageDataSource {}
class MockFileStorageDataSource extends Mock implements FileStorageDataSource {}

void main() {
  late StorageRepositoryImpl repository;
  late MockLocalStorageDataSource mockLocalDataSource;
  late MockFileStorageDataSource mockFileDataSource;

  setUp(() {
    mockLocalDataSource = MockLocalStorageDataSource();
    mockFileDataSource = MockFileStorageDataSource();
    repository = StorageRepositoryImpl(
      localDataSource: mockLocalDataSource,
      fileDataSource: mockFileDataSource,
    );
  });

  group('saveFitnessPlan', () {
    test('should save fitness plan with image successfully', () async {
      // arrange
      final testWorkoutPlan = TestFixtures.getTestWorkoutPlan();
      const imagePath = '/source/image.jpg';
      const storedImagePath = '/stored/image.jpg';
      
      when(mockFileDataSource.saveImageFile(imagePath))
          .thenAnswer((_) async => storedImagePath);
      when(mockLocalDataSource.saveFitnessPlan(any))
          .thenAnswer((_) async => {});

      // act
      final result = await repository.saveFitnessPlan(
        workoutPlan: testWorkoutPlan,
        imageFilePath: imagePath,
      );

      // assert
      expect(result, isA<StoredFitnessPlanEntity>());
      expect(result.imagePath, equals(storedImagePath));
      verify(mockFileDataSource.saveImageFile(imagePath)).called(1);
      verify(mockLocalDataSource.saveFitnessPlan(any)).called(1);
    });

    test('should save fitness plan without image successfully', () async {
      // arrange
      final testWorkoutPlan = TestFixtures.getTestWorkoutPlan();
      when(mockLocalDataSource.saveFitnessPlan(any))
          .thenAnswer((_) async => {});

      // act
      final result = await repository.saveFitnessPlan(
        workoutPlan: testWorkoutPlan,
      );

      // assert
      expect(result, isA<StoredFitnessPlanEntity>());
      expect(result.imagePath, isNull);
      verifyNever(mockFileDataSource.saveImageFile(any));
      verify(mockLocalDataSource.saveFitnessPlan(any)).called(1);
    });
  });

  group('getAllFitnessPlans', () {
    test('should return all fitness plans from local data source', () async {
      // arrange
      final testPlans = [
        TestFixtures.getTestStoredFitnessPlan(),
      ];
      when(mockLocalDataSource.getAllFitnessPlans())
          .thenAnswer((_) async => testPlans.map((p) => StoredFitnessPlanModel(
            id: p.id,
            workoutPlan: p.workoutPlan,
            imagePath: p.imagePath,
            createdAt: p.createdAt,
            updatedAt: p.updatedAt,
            isSynced: p.isSynced,
            cloudId: p.cloudId,
          )).toList());

      // act
      final result = await repository.getAllFitnessPlans();

      // assert
      expect(result.length, equals(1));
      verify(mockLocalDataSource.getAllFitnessPlans()).called(1);
    });
  });

  group('getFitnessPlanById', () {
    test('should return fitness plan when found', () async {
      // arrange
      const planId = 'plan-1';
      final testPlan = TestFixtures.getTestStoredFitnessPlan();
      when(mockLocalDataSource.getFitnessPlanById(planId))
          .thenAnswer((_) async => StoredFitnessPlanModel(
            id: testPlan.id,
            workoutPlan: testPlan.workoutPlan,
            imagePath: testPlan.imagePath,
            createdAt: testPlan.createdAt,
            updatedAt: testPlan.updatedAt,
            isSynced: testPlan.isSynced,
            cloudId: testPlan.cloudId,
          ));

      // act
      final result = await repository.getFitnessPlanById(planId);

      // assert
      expect(result, isNotNull);
      expect(result?.id, equals(planId));
      verify(mockLocalDataSource.getFitnessPlanById(planId)).called(1);
    });

    test('should return null when plan not found', () async {
      // arrange
      const planId = 'non-existent';
      when(mockLocalDataSource.getFitnessPlanById(planId))
          .thenAnswer((_) async => null);

      // act
      final result = await repository.getFitnessPlanById(planId);

      // assert
      expect(result, isNull);
      verify(mockLocalDataSource.getFitnessPlanById(planId)).called(1);
    });
  });

  group('deleteFitnessPlan', () {
    test('should delete fitness plan and associated image', () async {
      // arrange
      const planId = 'plan-1';
      final testPlan = TestFixtures.getTestStoredFitnessPlan();
      when(mockLocalDataSource.getFitnessPlanById(planId))
          .thenAnswer((_) async => StoredFitnessPlanModel(
            id: testPlan.id,
            workoutPlan: testPlan.workoutPlan,
            imagePath: testPlan.imagePath,
            createdAt: testPlan.createdAt,
            updatedAt: testPlan.updatedAt,
            isSynced: testPlan.isSynced,
            cloudId: testPlan.cloudId,
          ));
      when(mockFileDataSource.deleteImageFile(any))
          .thenAnswer((_) async => {});
      when(mockLocalDataSource.deleteFitnessPlan(planId))
          .thenAnswer((_) async => {});

      // act
      await repository.deleteFitnessPlan(planId);

      // assert
      verify(mockLocalDataSource.getFitnessPlanById(planId)).called(1);
      verify(mockFileDataSource.deleteImageFile(testPlan.imagePath!)).called(1);
      verify(mockLocalDataSource.deleteFitnessPlan(planId)).called(1);
    });
  });

  group('updateSyncStatus', () {
    test('should update sync status successfully', () async {
      // arrange
      const planId = 'plan-1';
      const cloudId = 'cloud-123';
      final testPlan = TestFixtures.getTestStoredFitnessPlan();
      when(mockLocalDataSource.getFitnessPlanById(planId))
          .thenAnswer((_) async => StoredFitnessPlanModel(
            id: testPlan.id,
            workoutPlan: testPlan.workoutPlan,
            imagePath: testPlan.imagePath,
            createdAt: testPlan.createdAt,
            updatedAt: testPlan.updatedAt,
            isSynced: testPlan.isSynced,
            cloudId: testPlan.cloudId,
          ));
      when(mockLocalDataSource.updateFitnessPlan(any))
          .thenAnswer((_) async => {});

      // act
      await repository.updateSyncStatus(
        id: planId,
        isSynced: true,
        cloudId: cloudId,
      );

      // assert
      verify(mockLocalDataSource.getFitnessPlanById(planId)).called(1);
      verify(mockLocalDataSource.updateFitnessPlan(any)).called(1);
    });

    test('should throw exception when plan not found', () async {
      // arrange
      const planId = 'non-existent';
      when(mockLocalDataSource.getFitnessPlanById(planId))
          .thenAnswer((_) async => null);

      // act & assert
      expect(
        () => repository.updateSyncStatus(
          id: planId,
          isSynced: true,
        ),
        throwsException,
      );
    });
  });
}

