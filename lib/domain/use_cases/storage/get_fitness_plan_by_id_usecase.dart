import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/repositories/storage_repository.dart';

/// Use case for getting a specific fitness plan by ID
class GetFitnessPlanByIdUsecase {
  final StorageRepository repository;

  GetFitnessPlanByIdUsecase(this.repository);

  Future<StoredFitnessPlanEntity?> call(String id) async {
    return await repository.getFitnessPlanById(id);
  }
}

