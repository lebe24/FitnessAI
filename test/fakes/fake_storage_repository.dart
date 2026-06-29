import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/repositories/storage_repository.dart';
import '../fixtures/fixtures.dart';

class FakeStorageRepository implements StorageRepository {
  final Map<String, StoredFitnessPlanEntity> _store = {};
  int _idCounter = 0;

  Exception? saveError;
  Exception? deleteError;
  Exception? updateSyncError;

  bool deleteCalled = false;
  String? lastDeletedId;

  // Pre-seed a list of plans returned by getAllFitnessPlans
  List<StoredFitnessPlanEntity> allPlansResult = [];

  void seed(StoredFitnessPlanEntity plan) => _store[plan.id] = plan;

  @override
  Future<StoredFitnessPlanEntity> saveFitnessPlan({
    required WorkoutPlanEntity workoutPlan,
    String? imageFilePath,
  }) async {
    if (saveError != null) throw saveError!;
    final id = 'plan-${++_idCounter}';
    final now = DateTime.now();
    final plan = StoredFitnessPlanEntity(
      id: id,
      workoutPlan: workoutPlan,
      imagePath: imageFilePath,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      cloudId: null,
    );
    _store[id] = plan;
    return plan;
  }

  @override
  Future<List<StoredFitnessPlanEntity>> getAllFitnessPlans() async {
    if (allPlansResult.isNotEmpty) return allPlansResult;
    return _store.values.toList();
  }

  @override
  Future<StoredFitnessPlanEntity?> getFitnessPlanById(String id) async =>
      _store[id];

  @override
  Future<void> deleteFitnessPlan(String id) async {
    if (deleteError != null) throw deleteError!;
    deleteCalled = true;
    lastDeletedId = id;
    _store.remove(id);
  }

  @override
  Future<void> updateSyncStatus({
    required String id,
    required bool isSynced,
    String? cloudId,
  }) async {
    if (updateSyncError != null) throw updateSyncError!;
    final existing = _store[id];
    if (existing == null) throw Exception('Plan $id not found');
    _store[id] = existing.copyWith(isSynced: isSynced, cloudId: cloudId);
  }

  @override
  Future<List<StoredFitnessPlanEntity>> getUnsyncedPlans() async =>
      _store.values.where((p) => !p.isSynced).toList();

  @override
  Future<String> saveImageFile(String sourcePath) async => '/stored/$sourcePath';

  @override
  Future<void> deleteImageFile(String imagePath) async {}
}
