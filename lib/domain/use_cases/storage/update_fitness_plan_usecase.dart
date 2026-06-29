import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/repositories/storage_repository.dart';

class UpdateFitnessPlanUsecase {
  final StorageRepository repository;
  UpdateFitnessPlanUsecase(this.repository);

  Future<void> call(StoredFitnessPlanEntity plan) async {
    return await repository.updateFitnessPlan(plan);
  }
}
