import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/models/workout_plan.dart';

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

  /// Update an existing fitness plan (replaces the stored plan data)
  Future<void> updateFitnessPlan(StoredFitnessPlanEntity plan);

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

