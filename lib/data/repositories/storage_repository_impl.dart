import 'package:fitness/data/services/storage/file_storage_service.dart';
import 'package:fitness/data/services/storage/local_storage_service.dart';
import 'package:fitness/data/services/storage/workout_plan_sync_service.dart';
import 'package:fitness/data/models/storage/stored_fitness_plan_model.dart';
import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/repositories/storage_repository.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:uuid/uuid.dart';

/// Implementation of StorageRepository
class StorageRepositoryImpl implements StorageRepository {
  final LocalStorageDataSource localDataSource;
  final FileStorageDataSource fileDataSource;
  final WorkoutPlanSyncDataSource syncDataSource;

  StorageRepositoryImpl({
    required this.localDataSource,
    required this.fileDataSource,
    required this.syncDataSource,
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

    // Save to local Hive first so the plan is available offline immediately.
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

    // Sync to backend — failure is non-fatal so the local plan always survives.
    try {
      final cloudId = await syncDataSource.saveToCloud(
        plan: workoutPlan,
        localImagePath: storedImagePath,
      );
      final synced = storedPlan.copyWith(isSynced: true, cloudId: cloudId, updatedAt: DateTime.now());
      await localDataSource.updateFitnessPlan(synced);
      return synced;
    } catch (_) {
      return storedPlan;
    }
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
  Future<void> updateFitnessPlan(StoredFitnessPlanEntity plan) async {
    final model = StoredFitnessPlanModel.fromEntity(
      plan.copyWith(updatedAt: DateTime.now(), isSynced: false),
    );
    await localDataSource.updateFitnessPlan(model);
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

