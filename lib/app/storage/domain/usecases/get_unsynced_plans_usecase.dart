import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/storage/domain/repositories/storage_repository.dart';

/// Use case for getting all unsynced fitness plans
class GetUnsyncedPlansUsecase {
  final StorageRepository repository;

  GetUnsyncedPlansUsecase(this.repository);

  Future<List<StoredFitnessPlanEntity>> call() async {
    return await repository.getUnsyncedPlans();
  }
}

