import 'package:fitness/domain/repositories/storage_repository.dart';

/// Use case for deleting a fitness plan
class DeleteFitnessPlanUsecase {
  final StorageRepository repository;

  DeleteFitnessPlanUsecase(this.repository);

  Future<void> call(String id) async {
    return await repository.deleteFitnessPlan(id);
  }
}

