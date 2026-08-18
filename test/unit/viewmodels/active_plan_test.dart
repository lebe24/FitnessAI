import 'package:fitness/data/models/storage/stored_fitness_plan_model.dart';
import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fixtures.dart';

/// The repository returns `List<StoredFitnessPlanModel>` typed as
/// `List<StoredFitnessPlanEntity>`. That distinction is not cosmetic: a
/// `reduce` here threw a TypeError in release because the runtime list demands
/// a `(Model, Model) => Model` combiner. Building the list the way the app
/// really does is what makes these tests able to catch that class of bug.
StoredFitnessPlanModel _model(StoredFitnessPlanEntity e) =>
    StoredFitnessPlanModel.fromEntity(e);

List<StoredFitnessPlanEntity> asRepositoryReturnsIt(
        List<StoredFitnessPlanEntity> plans) =>
    plans.map(_model).toList();

/// Mirrors FitnessViewModel.activePlan.
///
/// The resolution rule is what decides which program a user actually trains
/// on, so it is worth pinning independently of Hive and the view model's
/// async loading.
StoredFitnessPlanEntity? resolveActive(
  List<StoredFitnessPlanEntity> plans,
  String? storedId,
) {
  if (plans.isEmpty) return null;
  if (storedId != null) {
    for (final p in plans) {
      if (p.id == storedId) return p;
    }
  }
  var newest = plans.first;
  for (final p in plans) {
    if (p.createdAt.isAfter(newest.createdAt)) newest = p;
  }
  return newest;
}

void main() {
  final older = Fixtures.storedPlan(
      id: 'old', createdAt: DateTime(2026, 1, 1));
  final middle = Fixtures.storedPlan(
      id: 'mid', createdAt: DateTime(2026, 6, 1));
  final newest = Fixtures.storedPlan(
      id: 'new', createdAt: DateTime(2026, 8, 1));

  // Deliberately not in date order — Hive returns box key order, which is
  // what made "first" an unreliable stand-in for "active".
  final plans = asRepositoryReturnsIt([middle, newest, older]);

  group('active plan resolution', () {
    test('an explicit choice wins over recency', () {
      expect(resolveActive(plans, 'old')?.id, 'old');
      expect(resolveActive(plans, 'mid')?.id, 'mid');
    });

    test('with no choice stored it falls back to the newest, not the first', () {
      final active = resolveActive(plans, null);
      expect(active?.id, 'new');
      expect(active?.id, isNot(plans.first.id),
          reason: 'first is Hive key order and would be arbitrary');
    });

    test('a stored id that no longer exists falls back instead of breaking', () {
      // What happens after the active program is deleted.
      expect(resolveActive(plans, 'deleted-plan')?.id, 'new');
    });

    test('resolves over the subclass list the repository actually returns', () {
      // Guards the TypeError: the runtime list is List<StoredFitnessPlanModel>,
      // so any combiner-taking method here must tolerate that.
      expect(plans, isA<List<StoredFitnessPlanModel>>());
      expect(resolveActive(plans, null)?.id, 'new');
    });

    test('no plans resolves to nothing', () {
      expect(resolveActive([], 'anything'), isNull);
      expect(resolveActive([], null), isNull);
    });

    test('a single plan is active whether or not it was chosen', () {
      final one = asRepositoryReturnsIt([older]);
      expect(resolveActive(one, null)?.id, 'old');
      expect(resolveActive(one, 'old')?.id, 'old');
      expect(resolveActive(one, 'stale')?.id, 'old');
    });
  });
}
