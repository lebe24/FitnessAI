import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/repositories/storage_repository.dart';

/// Use case for getting all stored fitness plans
class GetAllFitnessPlansUsecase {
  final StorageRepository repository;

  GetAllFitnessPlansUsecase(this.repository);

  Future<List<StoredFitnessPlanEntity>> call() async {
    return await repository.getAllFitnessPlans();
  }
}

