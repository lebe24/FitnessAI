import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/repositories/storage_repository.dart';
import 'package:fitness/domain/models/workout_plan.dart';

/// Use case for saving a fitness plan
class SaveFitnessPlanUsecase {
  final StorageRepository repository;

  SaveFitnessPlanUsecase(this.repository);

  Future<StoredFitnessPlanEntity> call({
    required WorkoutPlanEntity workoutPlan,
    String? imageFilePath,
  }) async {
    return await repository.saveFitnessPlan(
      workoutPlan: workoutPlan,
      imageFilePath: imageFilePath,
    );
  }
}

