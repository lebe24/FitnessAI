import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/domain/use_cases/storage/save_fitness_plan_usecase.dart';
import 'package:fitness/domain/use_cases/storage/get_all_fitness_plans_usecase.dart';
import 'package:fitness/domain/use_cases/storage/get_fitness_plan_by_id_usecase.dart';
import 'package:fitness/domain/use_cases/storage/delete_fitness_plan_usecase.dart';
import '../../../fakes/fake_storage_repository.dart';
import '../../../fixtures/fixtures.dart';

void main() {
  // ── SaveFitnessPlanUsecase ─────────────────────────────────────────────────

  group('SaveFitnessPlanUsecase', () {
    late FakeStorageRepository repo;
    late SaveFitnessPlanUsecase usecase;

    setUp(() {
      repo = FakeStorageRepository();
      usecase = SaveFitnessPlanUsecase(repo);
    });

    test('saves plan with image and returns stored entity', () async {
      final result = await usecase(
        workoutPlan: Fixtures.workoutPlan(),
        imageFilePath: '/images/selfie.jpg',
      );
      expect(result.id, isNotEmpty);
      expect(result.imagePath, '/images/selfie.jpg');
      expect(result.isSynced, false);
    });

    test('saves plan without image (imagePath is null)', () async {
      final result = await usecase(workoutPlan: Fixtures.workoutPlan());
      expect(result.imagePath, isNull);
    });

    test('propagates exception from repository', () async {
      repo.saveError = Exception('Disk full');
      expect(
        () => usecase(workoutPlan: Fixtures.workoutPlan()),
        throwsException,
      );
    });
  });

  // ── GetAllFitnessPlansUsecase ──────────────────────────────────────────────

  group('GetAllFitnessPlansUsecase', () {
    late FakeStorageRepository repo;
    late GetAllFitnessPlansUsecase usecase;

    setUp(() {
      repo = FakeStorageRepository();
      usecase = GetAllFitnessPlansUsecase(repo);
    });

    test('returns all plans from repository', () async {
      repo.allPlansResult = [Fixtures.storedPlan(), Fixtures.storedPlan(id: 'plan-002')];
      final result = await usecase();
      expect(result.length, 2);
    });

    test('returns empty list when no plans exist', () async {
      repo.allPlansResult = [];
      final result = await usecase();
      expect(result, isEmpty);
    });
  });

  // ── GetFitnessPlanByIdUsecase ──────────────────────────────────────────────

  group('GetFitnessPlanByIdUsecase', () {
    late FakeStorageRepository repo;
    late GetFitnessPlanByIdUsecase usecase;

    setUp(() {
      repo = FakeStorageRepository();
      usecase = GetFitnessPlanByIdUsecase(repo);
    });

    test('returns plan when it exists', () async {
      repo.seed(Fixtures.storedPlan(id: 'plan-001'));
      final result = await usecase('plan-001');
      expect(result?.id, 'plan-001');
    });

    test('returns null when plan does not exist', () async {
      final result = await usecase('not-here');
      expect(result, isNull);
    });
  });

  // ── DeleteFitnessPlanUsecase ───────────────────────────────────────────────

  group('DeleteFitnessPlanUsecase', () {
    late FakeStorageRepository repo;
    late DeleteFitnessPlanUsecase usecase;

    setUp(() {
      repo = FakeStorageRepository();
      usecase = DeleteFitnessPlanUsecase(repo);
    });

    test('calls repository delete and plan is removed', () async {
      repo.seed(Fixtures.storedPlan(id: 'plan-001'));
      await usecase('plan-001');
      expect(repo.deleteCalled, true);
      expect(repo.lastDeletedId, 'plan-001');
      expect(await repo.getFitnessPlanById('plan-001'), isNull);
    });

    test('propagates exception from repository', () async {
      repo.deleteError = Exception('Delete failed');
      expect(() => usecase('plan-001'), throwsException);
    });
  });
}
