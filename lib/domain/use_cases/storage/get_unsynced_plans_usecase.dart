import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/repositories/storage_repository.dart';

/// Use case for getting all unsynced fitness plans
class GetUnsyncedPlansUsecase {
  final StorageRepository repository;

  GetUnsyncedPlansUsecase(this.repository);

  Future<List<StoredFitnessPlanEntity>> call() async {
    return await repository.getUnsyncedPlans();
  }
}

