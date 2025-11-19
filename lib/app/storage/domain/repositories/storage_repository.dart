import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';

/// Repository interface for storing and retrieving fitness plans
abstract class StorageRepository {
  /// Save a fitness plan with optional image
  /// Returns the stored entity with generated ID
  Future<StoredFitnessPlanEntity> saveFitnessPlan({
    required WorkoutPlanEntity workoutPlan,
    String? imageFilePath, // Path to image file to be stored
  });

  /// Get all stored fitness plans
  Future<List<StoredFitnessPlanEntity>> getAllFitnessPlans();

  /// Get a specific fitness plan by ID
  Future<StoredFitnessPlanEntity?> getFitnessPlanById(String id);

  /// Delete a fitness plan and its associated image
  Future<void> deleteFitnessPlan(String id);

  /// Update sync status of a fitness plan
  Future<void> updateSyncStatus({
    required String id,
    required bool isSynced,
    String? cloudId,
  });

  /// Get all unsynced fitness plans
  Future<List<StoredFitnessPlanEntity>> getUnsyncedPlans();

  /// Save image file and return the stored file path
  Future<String> saveImageFile(String sourcePath);

  /// Delete image file by path
  Future<void> deleteImageFile(String imagePath);
}

