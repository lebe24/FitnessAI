import 'package:fitness/app/storage/domain/repositories/storage_repository.dart';

/// Use case for updating sync status of a fitness plan
class UpdateSyncStatusUsecase {
  final StorageRepository repository;

  UpdateSyncStatusUsecase(this.repository);

  Future<void> call({
    required String id,
    required bool isSynced,
    String? cloudId,
  }) async {
    return await repository.updateSyncStatus(
      id: id,
      isSynced: isSynced,
      cloudId: cloudId,
    );
  }
}

