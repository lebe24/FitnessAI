import 'package:fitness/data/repositories/body_tracking_repository.dart';
import 'package:fitness/domain/body/body_advice.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/goal_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_body_tracking.dart';

final _now = DateTime(2026, 11, 25, 9);

BodyWeightEntry _w(int daysAgo, double kg) =>
    BodyWeightEntry(date: DateTime(2026, 11, 25).subtract(Duration(days: daysAgo)), weightKg: kg);

BodyMeasurement _m(int daysAgo, MeasurementSite site, double cm) => BodyMeasurement(
    date: DateTime(2026, 11, 25).subtract(Duration(days: daysAgo)), site: site, valueCm: cm);

void main() {
  late FakeBodyRemote remote;
  late MemoryBodyStore store;
  double? legacy;

  String? user = 'user-a';

  BodyTrackingRepository repo() => BodyTrackingRepository(
        remote: remote,
        store: store,
        legacyWeightKg: () async => legacy,
        currentUserId: () => user,
        now: () => _now,
      );

  setUp(() {
    remote = FakeBodyRemote();
    store = MemoryBodyStore();
    legacy = null;
    user = 'user-a';
  });

  group('logging weight', () {
    test('is saved on the server and in the device copy, oldest first', () async {
      final r = repo();
      await r.logWeight(_w(0, 79.4));
      final s = await r.logWeight(_w(2, 80));
      expect(s.weights.map((e) => e.weightKg), [80, 79.4]);
      expect(s.weights.every((e) => e.id != null), isTrue, reason: 'the server gave each an id');
      expect(remote.weights.length, 2);
      expect(s.hasPending, isFalse);
    });

    test('a second weigh-in on one day replaces the first', () async {
      final r = repo();
      await r.logWeight(_w(0, 80));
      final s = await r.logWeight(_w(0, 79.6));
      expect(s.weights.map((e) => e.weightKg), [79.6]);
      expect(remote.weights.length, 1);
    });

    test('offline, it is kept on the device and marked pending', () async {
      remote.offline = true;
      final s = await repo().logWeight(_w(0, 80));
      expect(s.weights.single.weightKg, 80);
      expect(s.pendingWeights.single.weightKg, 80);
      expect(remote.weights, isEmpty);
    });

    test('pending entries go up on the next refresh and are cleared', () async {
      remote.offline = true;
      final r = repo();
      await r.logWeight(_w(1, 80));
      await r.logMeasurements([_m(1, MeasurementSite.waist, 85)]);

      remote.offline = false;
      final s = await r.refresh();

      expect(remote.syncCalls, 1);
      expect(remote.weights.single.weightKg, 80);
      expect(s.hasPending, isFalse);
      expect(s.weights.single.id, isNotNull);
      expect(s.measurements.single.valueCm, 85);
    });

    test('an entry corrected offline replaces the earlier pending one', () async {
      remote.offline = true;
      final r = repo();
      await r.logWeight(_w(0, 80));
      final s = await r.logWeight(_w(0, 79.5));
      expect(s.pendingWeights.map((e) => e.weightKg), [79.5]);
    });

    test('deleting removes it from the server and the device', () async {
      final r = repo();
      final s = await r.logWeight(_w(0, 80));
      final after = await r.deleteWeight(s.weights.single);
      expect(after.weights, isEmpty);
      expect(remote.weights, isEmpty);
    });
  });

  group('measurements', () {
    test('several are saved together, and the device takes the server ids', () async {
      final s = await repo().logMeasurements([
        _m(0, MeasurementSite.chest, 101.5),
        _m(0, MeasurementSite.waist, 84),
      ]);
      expect(s.measurements.length, 2);
      expect(s.measurements.every((m) => m.id != null), isTrue);
    });

    test('logging a site again that day replaces it', () async {
      final r = repo();
      await r.logMeasurements([_m(0, MeasurementSite.waist, 84)]);
      final s = await r.logMeasurements([_m(0, MeasurementSite.waist, 83.2)]);
      expect(s.measurements.map((m) => m.valueCm), [83.2]);
    });

    test('offline, they wait', () async {
      remote.offline = true;
      final s = await repo().logMeasurements([_m(0, MeasurementSite.hips, 95)]);
      expect(s.pendingMeasurements.length, 1);
      expect(s.measurements.length, 1);
    });

    test('nothing to log is a no-op', () async {
      final s = await repo().logMeasurements(const []);
      expect(s.measurements, isEmpty);
    });
  });

  group('goal', () {
    test('starts from the latest weigh-in when no start weight is given', () async {
      final r = repo();
      await r.logWeight(_w(0, 82));
      final s = await r.saveGoal(const FitnessGoal(type: GoalType.loseWeight, targetWeightKg: 76));
      expect(s.goal!.startWeightKg, 82);
      expect(s.goal!.id, isNotNull);
      expect(s.goalPending, isFalse);
    });

    test('offline, the goal is kept and goes up later', () async {
      remote.offline = true;
      final r = repo();
      final s = await r.saveGoal(const FitnessGoal(
          type: GoalType.buildMuscle, focusMuscles: [MuscleGroup.quads, MuscleGroup.chest]));
      expect(s.goalPending, isTrue);
      expect(s.goal!.focusMuscles, [MuscleGroup.quads, MuscleGroup.chest]);

      remote.offline = false;
      final after = await r.refresh();
      expect(after.goalPending, isFalse);
      expect(remote.goal!.focusMuscles, [MuscleGroup.quads, MuscleGroup.chest]);
    });

    test('can be cleared', () async {
      final r = repo();
      await r.saveGoal(const FitnessGoal(type: GoalType.maintain));
      final s = await r.clearGoal();
      expect(s.goal, isNull);
      expect(remote.goal, isNull);
    });
  });

  group('refresh', () {
    test('replaces the device copy with the server and sorts it', () async {
      remote.weights.addAll([_w(0, 79), _w(5, 81)]);
      remote.goal = const FitnessGoal(id: 'g', type: GoalType.maintain);
      final s = await repo().refresh();
      expect(s.weights.map((e) => e.weightKg), [81, 79]);
      expect(s.goal!.id, 'g');
    });

    test('offline it throws and leaves the device copy alone', () async {
      final r = repo();
      await r.logWeight(_w(0, 80));
      remote.offline = true;
      await expectLater(r.refresh(), throwsA(isA<BodyTrackingException>()));
      expect((await r.load()).weights.single.weightKg, 80);
    });

    test('starts the log from the old single weight, once', () async {
      legacy = 78.4;
      final r = repo();
      final first = await r.refresh();
      expect(first.weights.single.weightKg, 78.4);
      expect(first.legacySeeded, isTrue);

      // Deleting it must not bring it back on the next refresh.
      await r.deleteWeight(first.weights.single);
      final second = await r.refresh();
      expect(second.weights, isEmpty);
    });

    test('does not seed when the server already has weigh-ins', () async {
      legacy = 78.4;
      remote.weights.add(_w(3, 80));
      final s = await repo().refresh();
      expect(s.weights.single.weightKg, 80);
    });

    test('ignores an implausible old weight', () async {
      legacy = 4;
      expect((await repo().refresh()).weights, isEmpty);
    });
  });

  group('advice', () {
    BodyAdvice advice() => BodyAdvice(
          status: ProgressStatus.onTrack,
          headline: 'On track',
          summary: 's',
          actions: const [],
          disclaimer: 'd',
          generatedAt: _now,
        );

    test('is asked for, kept on the device and read back', () async {
      remote.nextAdvice = advice();
      final r = repo();
      final got = await r.advise(const AdviceRequest(
          sessionsLogged: 1, workoutsPerWeek: 1, volumeLast28DaysKg: 0, streakDays: 0, muscles: []));
      expect(got.headline, 'On track');
      expect((await r.cachedAdvice())!.headline, 'On track');
    });

    test('passes a premium refusal up', () async {
      remote.adviceError = BodyTrackingError.premiumRequired;
      await expectLater(
        repo().advise(const AdviceRequest(
            sessionsLogged: 0, workoutsPerWeek: 0, volumeLast28DaysKg: 0, streakDays: 0, muscles: [])),
        throwsA(isA<BodyTrackingException>()
            .having((e) => e.error, 'error', BodyTrackingError.premiumRequired)),
      );
    });
  });

  test('a scan that cannot be stored is not an error', () async {
    remote.offline = true;
    await repo().recordScan({'body_fat_pct': 18});
    remote.offline = false;
    await repo().recordScan({'body_fat_pct': 18});
    expect(remote.scans.length, 1);
  });

  group('a second account on the same phone', () {
    test('does not see or send the first account\'s data', () async {
      remote.offline = true;
      await repo().logWeight(_w(0, 80)); // user A, offline: pending

      user = 'user-b';
      remote.offline = false;
      final s = await repo().refresh();

      expect(s.weights, isEmpty);
      expect(s.hasPending, isFalse);
      expect(remote.weights, isEmpty, reason: 'A\'s pending weigh-in must not reach B\'s account');
      expect(s.ownerId, 'user-b');
    });

    test('the first account\'s advice is dropped too', () async {
      remote.nextAdvice = BodyAdvice(
        status: ProgressStatus.onTrack, headline: 'A', summary: '', actions: const [],
        disclaimer: '', generatedAt: _now,
      );
      await repo().advise(const AdviceRequest(
          sessionsLogged: 0, workoutsPerWeek: 0, volumeLast28DaysKg: 0, streakDays: 0, muscles: []));
      user = 'user-b';
      expect(await repo().cachedAdvice(), isNull);
    });

    test('the same account keeps its data', () async {
      final r = repo();
      await r.logWeight(_w(0, 80));
      expect((await repo().load()).weights.single.weightKg, 80);
    });
  });
}
