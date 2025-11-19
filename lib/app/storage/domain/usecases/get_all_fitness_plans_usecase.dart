import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/storage/domain/repositories/storage_repository.dart';

/// Use case for getting all stored fitness plans
class GetAllFitnessPlansUsecase {
  final StorageRepository repository;

  GetAllFitnessPlansUsecase(this.repository);

  Future<List<StoredFitnessPlanEntity>> call() async {
    return await repository.getAllFitnessPlans();
  }
}

