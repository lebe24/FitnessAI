import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/storage/domain/repositories/storage_repository.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';

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

