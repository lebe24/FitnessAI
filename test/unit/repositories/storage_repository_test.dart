import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/data/repositories/storage_repository_impl.dart';
import 'package:fitness/data/services/storage/local_storage_service.dart';
import 'package:fitness/data/services/storage/file_storage_service.dart';
import 'package:fitness/data/models/storage/stored_fitness_plan_model.dart';
import 'package:fitness/domain/models/stored_fitness_plan.dart';
import '../../fixtures/fixtures.dart';

// ── Fake data sources ─────────────────────────────────────────────────────────

class FakeLocalStorage implements LocalStorageDataSource {
  final Map<String, StoredFitnessPlanModel> _store = {};
  final List<String> deletedIds = [];
  final List<StoredFitnessPlanModel> updatedPlans = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> saveFitnessPlan(StoredFitnessPlanModel plan) async =>
      _store[plan.id] = plan;

  @override
  Future<List<StoredFitnessPlanModel>> getAllFitnessPlans() async =>
      _store.values.toList();

  @override
  Future<StoredFitnessPlanModel?> getFitnessPlanById(String id) async =>
      _store[id];

  @override
  Future<void> deleteFitnessPlan(String id) async {
    deletedIds.add(id);
    _store.remove(id);
  }

  @override
  Future<void> updateFitnessPlan(StoredFitnessPlanModel plan) async {
    updatedPlans.add(plan);
    _store[plan.id] = plan;
  }

  @override
  Future<List<StoredFitnessPlanModel>> getUnsyncedPlans() async =>
      _store.values.where((p) => !p.isSynced).toList();
}

class FakeFileStorage implements FileStorageDataSource {
  String savedImagePath = '/stored/image.jpg';
  final List<String> deletedImages = [];
  int saveCallCount = 0;

  @override
  Future<String> saveImageFile(String sourcePath) async {
    saveCallCount++;
    return savedImagePath;
  }

  @override
  Future<void> deleteImageFile(String imagePath) async =>
      deletedImages.add(imagePath);

  @override
  Future<bool> imageFileExists(String imagePath) async => false;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeLocalStorage localStore;
  late FakeFileStorage fileStore;
  late StorageRepositoryImpl repo;

  setUp(() {
    localStore = FakeLocalStorage();
    fileStore = FakeFileStorage();
    repo = StorageRepositoryImpl(
      localDataSource: localStore,
      fileDataSource: fileStore,
    );
  });

  group('saveFitnessPlan', () {
    test('saves with image — copies image file and persists plan', () async {
      final result = await repo.saveFitnessPlan(
        workoutPlan: Fixtures.workoutPlan(),
        imageFilePath: '/source/selfie.jpg',
      );
      expect(result, isA<StoredFitnessPlanEntity>());
      expect(result.imagePath, '/stored/image.jpg');
      expect(fileStore.saveCallCount, 1);
      expect(localStore._store.length, 1);
    });

    test('saves without image — no file copy, imagePath is null', () async {
      final result = await repo.saveFitnessPlan(
        workoutPlan: Fixtures.workoutPlan(),
      );
      expect(result.imagePath, isNull);
      expect(fileStore.saveCallCount, 0);
    });

    test('generated id is unique per save', () async {
      final a = await repo.saveFitnessPlan(workoutPlan: Fixtures.workoutPlan());
      final b = await repo.saveFitnessPlan(workoutPlan: Fixtures.workoutPlan());
      expect(a.id, isNot(equals(b.id)));
    });
  });

  group('getAllFitnessPlans', () {
    test('returns all persisted plans', () async {
      await repo.saveFitnessPlan(workoutPlan: Fixtures.workoutPlan());
      await repo.saveFitnessPlan(workoutPlan: Fixtures.workoutPlan());
      final result = await repo.getAllFitnessPlans();
      expect(result.length, 2);
    });

    test('returns empty list when nothing saved', () async {
      final result = await repo.getAllFitnessPlans();
      expect(result, isEmpty);
    });
  });

  group('getFitnessPlanById', () {
    test('returns plan when found', () async {
      final saved = await repo.saveFitnessPlan(workoutPlan: Fixtures.workoutPlan());
      final result = await repo.getFitnessPlanById(saved.id);
      expect(result?.id, saved.id);
    });

    test('returns null when not found', () async {
      final result = await repo.getFitnessPlanById('ghost-id');
      expect(result, isNull);
    });
  });

  group('deleteFitnessPlan', () {
    test('deletes plan and its associated image', () async {
      final saved = await repo.saveFitnessPlan(
        workoutPlan: Fixtures.workoutPlan(),
        imageFilePath: '/source/image.jpg',
      );
      await repo.deleteFitnessPlan(saved.id);

      expect(localStore.deletedIds, contains(saved.id));
      expect(fileStore.deletedImages, contains('/stored/image.jpg'));
    });

    test('deletes plan without image — no file delete called', () async {
      final saved = await repo.saveFitnessPlan(workoutPlan: Fixtures.workoutPlan());
      await repo.deleteFitnessPlan(saved.id);
      expect(localStore.deletedIds, contains(saved.id));
      expect(fileStore.deletedImages, isEmpty);
    });
  });

  group('updateSyncStatus', () {
    test('marks plan as synced with cloud id', () async {
      final saved = await repo.saveFitnessPlan(workoutPlan: Fixtures.workoutPlan());
      await repo.updateSyncStatus(
        id: saved.id,
        isSynced: true,
        cloudId: 'cloud-abc',
      );
      expect(localStore.updatedPlans.last.isSynced, true);
      expect(localStore.updatedPlans.last.cloudId, 'cloud-abc');
    });

    test('throws when plan not found', () async {
      expect(
        () => repo.updateSyncStatus(id: 'ghost', isSynced: true),
        throwsException,
      );
    });
  });
}
