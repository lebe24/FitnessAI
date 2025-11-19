import 'package:fitness/app/storage/data/datasources/file_storage_datasource.dart';
import 'package:fitness/app/storage/data/datasources/local_storage_datasource.dart';
import 'package:fitness/app/storage/data/models/stored_fitness_plan_model.dart';
import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/storage/domain/repositories/storage_repository.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';
import 'package:uuid/uuid.dart';

/// Implementation of StorageRepository
class StorageRepositoryImpl implements StorageRepository {
  final LocalStorageDataSource localDataSource;
  final FileStorageDataSource fileDataSource;

  StorageRepositoryImpl({
    required this.localDataSource,
    required this.fileDataSource,
  });

  @override
  Future<StoredFitnessPlanEntity> saveFitnessPlan({
    required WorkoutPlanEntity workoutPlan,
    String? imageFilePath,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    String? storedImagePath;
    if (imageFilePath != null) {
      storedImagePath = await fileDataSource.saveImageFile(imageFilePath);
    }

    final storedPlan = StoredFitnessPlanModel(
      id: id,
      workoutPlan: workoutPlan,
      imagePath: storedImagePath,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      cloudId: null,
    );

    await localDataSource.saveFitnessPlan(storedPlan);

    return storedPlan;
  }

  @override
  Future<List<StoredFitnessPlanEntity>> getAllFitnessPlans() async {
    final plans = await localDataSource.getAllFitnessPlans();
    return plans;
  }

  @override
  Future<StoredFitnessPlanEntity?> getFitnessPlanById(String id) async {
    return await localDataSource.getFitnessPlanById(id);
  }

  @override
  Future<void> deleteFitnessPlan(String id) async {
    // Get the plan first to delete associated image
    final plan = await localDataSource.getFitnessPlanById(id);
    if (plan != null && plan.imagePath != null) {
      await fileDataSource.deleteImageFile(plan.imagePath!);
    }
    await localDataSource.deleteFitnessPlan(id);
  }

  @override
  Future<void> updateSyncStatus({
    required String id,
    required bool isSynced,
    String? cloudId,
  }) async {
    final plan = await localDataSource.getFitnessPlanById(id);
    if (plan == null) {
      throw Exception('Fitness plan not found: $id');
    }

    final updatedPlan = plan.copyWith(
      isSynced: isSynced,
      cloudId: cloudId,
      updatedAt: DateTime.now(),
    );

    await localDataSource.updateFitnessPlan(updatedPlan);
  }

  @override
  Future<List<StoredFitnessPlanEntity>> getUnsyncedPlans() async {
    return await localDataSource.getUnsyncedPlans();
  }

  @override
  Future<String> saveImageFile(String sourcePath) async {
    return await fileDataSource.saveImageFile(sourcePath);
  }

  @override
  Future<void> deleteImageFile(String imagePath) async {
    await fileDataSource.deleteImageFile(imagePath);
  }
}

