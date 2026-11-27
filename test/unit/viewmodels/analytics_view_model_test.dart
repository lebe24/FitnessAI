import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_events.dart';
import 'package:fitness/data/services/analytics/analytics_service.dart';
import 'package:fitness/data/repositories/body_tracking_repository.dart';
import 'package:fitness/data/services/workout_log/exercise_history_service.dart';
import 'package:fitness/domain/body/body_advice.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/goal_progress.dart';
import 'package:fitness/domain/body/muscle_focus.dart';
import 'package:fitness/domain/body/scan_summary.dart';
import 'package:fitness/ui/features/analytic/view_models/analytics_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_body_tracking.dart';
import '../../fakes/recording_analytics.dart';

final _now = DateTime(2026, 11, 25, 9);

String _sets(int n, int reps, num kg) =>
    [for (var i = 1; i <= n; i++) 'set $i: $reps reps @ ${kg}kg'].join(' | ');

List<WorkoutSessionModel> _benchSessions() => [
      for (var w = 0; w < 4; w++)
        WorkoutSessionModel(
          sessionDate: DateTime(2026, 11, 25).subtract(Duration(days: 2 + w * 7)),
          workoutLogs: [
            {'name': 'Bench Press', 'sets': 12, 'reps': '8', 'notes': _sets(12, 8, 60)}
          ],
        ),
    ];

BodyAdvice _advice() => BodyAdvice(
      status: ProgressStatus.onTrack,
      headline: 'You are on track',
      summary: 'Keep going.',
      actions: const [AdviceAction(title: 'Measure', detail: 'Monthly.')],
      disclaimer: 'd',
      generatedAt: _now,
    );

void main() {
  late FakeBodyRemote remote;
  late MemoryBodyStore store;
  late List<WorkoutSessionModel>? sessions;
  ScanSummary? scan;
  var pro = true;

  AnalyticsViewModel vm() => AnalyticsViewModel(
        repo: BodyTrackingRepository(remote: remote, store: store, now: () => _now),
        history: ExerciseHistoryService(fetch: () async => sessions, now: () => _now),
        latestScan: () async => scan,
        canUse: (f) => pro,
        now: () => _now,
      );

  setUp(() {
    remote = FakeBodyRemote();
    store = MemoryBodyStore();
    sessions = _benchSessions();
    scan = null;
    pro = true;
  });

  test('loads the goal, the log and the muscle map', () async {
    remote.goal = const FitnessGoal(id: 'g', type: GoalType.buildMuscle);
    remote.weights.add(BodyWeightEntry(date: DateTime(2026, 11, 24), weightKg: 80));
    final v = vm();
    await v.load();

    expect(v.goal!.type, GoalType.buildMuscle);
    expect(v.latestWeight!.weightKg, 80);
    expect(v.muscles.length, MuscleGroup.values.length);
    expect(v.muscles.firstWhere((m) => m.group == MuscleGroup.chest).level, MuscleLevel.strong);
    expect(v.offline, isFalse);
  });

  test('offline it shows the device copy and says so', () async {
    final first = vm();
    await first.load();
    await first.logWeight(79);

    remote.offline = true;
    final v = vm();
    await v.load();
    expect(v.latestWeight!.weightKg, 79);
    expect(v.offline, isTrue);
  });

  group('logging', () {
    test('a weigh-in updates the progress', () async {
      final v = vm();
      await v.load();
      await v.saveGoal(const FitnessGoal(type: GoalType.loseWeight, startWeightKg: 82, targetWeightKg: 76));
      await v.logWeight(80);
      expect(v.progress.percentComplete, 33);
      expect(v.weights.length, 1);
    });

    test('refuses a weight no one has', () async {
      final v = vm();
      await v.load();
      expect(await v.logWeight(5), isFalse);
      expect(await v.logWeight(900), isFalse);
      expect(v.weights, isEmpty);
    });

    test('offline entries are kept and flagged pending', () async {
      final v = vm();
      await v.load();
      remote.offline = true;
      await v.logWeight(80);
      expect(v.hasPending, isTrue);
      expect(v.offline, isTrue);
      expect(v.latestWeight!.weightKg, 80);
    });

    test('measurements: implausible readings are dropped, the rest saved', () async {
      final v = vm();
      await v.load();
      final saved = await v.logMeasurements({
        MeasurementSite.chest: 101,
        MeasurementSite.waist: 2, // not a waist
        MeasurementSite.hips: 400,
      });
      expect(saved, 1);
      expect(v.measurementSummary.keys, [MeasurementSite.chest]);
    });

    test('measurement summary shows the change since the first reading', () async {
      final v = vm();
      await v.load();
      await v.logMeasurements({MeasurementSite.waist: 90}, date: DateTime(2026, 10, 1));
      await v.logMeasurements({MeasurementSite.waist: 86.5}, date: DateTime(2026, 11, 20));
      final s = v.measurementSummary[MeasurementSite.waist]!;
      expect(s.latestCm, 86.5);
      expect(s.changeCm, closeTo(-3.5, 1e-9));
    });
  });

  group('goal and focus', () {
    test('pinning a muscle saves it on the goal and marks it a focus area', () async {
      final v = vm();
      await v.load();
      await v.saveGoal(const FitnessGoal(type: GoalType.buildMuscle));
      expect(await v.setFocus(MuscleGroup.quads, focus: true), isTrue);
      expect(remote.goal!.focusMuscles, [MuscleGroup.quads]);
      final quads = v.muscles.firstWhere((m) => m.group == MuscleGroup.quads);
      expect(quads.level, MuscleLevel.focus);
      expect(v.focusAreas.map((m) => m.group), contains(MuscleGroup.quads));
    });

    test('unpinning removes it', () async {
      final v = vm();
      await v.load();
      await v.saveGoal(const FitnessGoal(type: GoalType.buildMuscle, focusMuscles: [MuscleGroup.quads]));
      await v.setFocus(MuscleGroup.quads, focus: false);
      expect(v.goal!.focusMuscles, isEmpty);
    });

    test('without a goal there is nowhere to keep a focus', () async {
      final v = vm();
      await v.load();
      expect(await v.setFocus(MuscleGroup.chest, focus: true), isFalse);
    });

    test('no more than six', () async {
      final v = vm();
      await v.load();
      await v.saveGoal(FitnessGoal(type: GoalType.buildMuscle, focusMuscles: MuscleGroup.values.take(6).toList()));
      expect(await v.setFocus(MuscleGroup.calves, focus: true), isFalse);
    });

    test('the goal type changes what counts as enough work', () async {
      final v = vm();
      await v.load();
      final before = v.muscles.firstWhere((m) => m.group == MuscleGroup.chest).targetSets;
      await v.saveGoal(const FitnessGoal(type: GoalType.maintain));
      expect(v.muscles.firstWhere((m) => m.group == MuscleGroup.chest).targetSets, lessThan(before));
    });

    test('the latest scan feeds the muscle scores', () async {
      scan = ScanSummary(
        scannedAt: _now, overall: 70, aesthetics: 70, muscleDevelopment: 70, conditioning: 70,
        posture: 70, bodyFatPct: 18, muscleMassPct: 40, groupScores: const {MuscleGroup.calves: 3},
      );
      final v = vm();
      await v.load();
      expect(v.muscles.firstWhere((m) => m.group == MuscleGroup.calves).level, MuscleLevel.focus);
      expect(v.scan!.bodyFatPct, 18);
    });

    test('a goal that cannot be saved offline is kept for later and still returns true', () async {
      final v = vm();
      await v.load();
      remote.offline = true;
      expect(await v.saveGoal(const FitnessGoal(type: GoalType.maintain)), isTrue);
      expect(v.goal, isNotNull);
      expect(v.hasPending, isTrue);
    });
  });

  group('advice', () {
    test('is fetched with the training summary and the muscle map', () async {
      remote.nextAdvice = _advice();
      final v = vm()..streakDays = 5;
      await v.load();
      await v.refreshAdvice(force: true);

      expect(v.advice!.headline, 'You are on track');
      final sent = remote.lastAdviceRequest!;
      expect(sent.forceRefresh, isTrue);
      expect(sent.streakDays, 5);
      expect(sent.workoutsPerWeek, 1.0);
      expect(sent.volumeLast28DaysKg, 4 * 12 * 8 * 60);
      expect(sent.muscles.map((m) => m.group), contains(MuscleGroup.chest));
      expect(sent.muscles.every((m) => m.level != MuscleLevel.untrained), isTrue);
    });

    test('the last answer is there when the screen opens offline', () async {
      remote.nextAdvice = _advice();
      final first = vm();
      await first.load();
      await first.refreshAdvice();

      final v = vm();
      await v.load();
      expect(v.advice!.headline, 'You are on track');
    });

    test('a premium refusal is reported, not thrown', () async {
      remote.adviceError = BodyTrackingError.premiumRequired;
      final v = vm();
      await v.load();
      await v.refreshAdvice();
      expect(v.adviceError, BodyTrackingError.premiumRequired);
      expect(v.adviceLoading, isFalse);
    });

    test('an offline phone reports it and keeps older advice', () async {
      remote.nextAdvice = _advice();
      final v = vm();
      await v.load();
      await v.refreshAdvice();
      remote.offline = true;
      await v.refreshAdvice(force: true);
      expect(v.adviceError, BodyTrackingError.offline);
      expect(v.advice, isNotNull);
    });
  });

  test('reflects whether the user has Pro', () async {
    pro = false;
    expect(vm().hasBodyTracking, isFalse);
    pro = true;
    expect(vm().hasGoalAdvice, isTrue);
  });

  group('analytics', () {
    late RecordingAnalytics rec;
    setUp(() {
      rec = RecordingAnalytics();
      Analytics.use(rec);
    });
    tearDown(() => Analytics.use(NoopAnalyticsService()));

    List<Map<String, Object?>?> named(String name) =>
        [for (final e in rec.events) if (e.$1 == name) e.$2];

    test('logging a weight says how, never how much', () async {
      final v = vm();
      await v.load();
      await v.logWeight(81.7, note: 'after a long run', source: 'quick');

      expect(named('weight_logged'), [
        {'source': 'quick', 'backdated': false, 'has_note': true, 'offline': false}
      ]);
    });

    test('a weigh-in for an earlier day is marked backdated', () async {
      final v = vm();
      await v.load();
      await v.logWeight(81, date: DateTime(2026, 11, 10));
      expect(named('weight_logged').single!['backdated'], isTrue);
    });

    test('a weight nobody can have is not reported', () async {
      final v = vm();
      await v.load();
      await v.logWeight(5);
      expect(named('weight_logged'), isEmpty);
    });

    test('an offline weigh-in is reported as offline', () async {
      remote.offline = true;
      final v = vm();
      await v.load();
      await v.logWeight(80);
      expect(named('weight_logged').single!['offline'], isTrue);
    });

    test('measurements say how many sites, not what they measured', () async {
      final v = vm();
      await v.load();
      await v.logMeasurements({MeasurementSite.waist: 84.2, MeasurementSite.chest: 101.1});
      expect(named('measurements_logged'), [
        {'sites': 2}
      ]);
    });

    test('nothing is reported when every reading was out of range', () async {
      final v = vm();
      await v.load();
      await v.logMeasurements({MeasurementSite.waist: 1});
      expect(named('measurements_logged'), isEmpty);
    });

    test('setting a goal says what kind, never the target', () async {
      final v = vm();
      await v.load();
      await v.saveGoal(FitnessGoal(
        type: GoalType.loseWeight,
        targetWeightKg: 76,
        targetDate: DateTime(2027, 1, 20),
        focusMuscles: const [MuscleGroup.quads, MuscleGroup.chest],
      ));

      expect(named('goal_set'), [
        {'type': 'loseWeight', 'has_target_weight': true, 'has_target_date': true, 'focus_count': 2, 'replaced': false}
      ]);
    });

    test('changing a goal is marked as replacing one', () async {
      final v = vm();
      await v.load();
      await v.saveGoal(const FitnessGoal(type: GoalType.maintain));
      await v.saveGoal(const FitnessGoal(type: GoalType.buildMuscle));
      expect(named('goal_set').last!['replaced'], isTrue);
    });

    test('a goal set with no signal is still reported: it is kept and synced later', () async {
      remote.offline = true;
      final v = vm();
      await v.load();
      expect(await v.saveGoal(const FitnessGoal(type: GoalType.maintain)), isTrue);
      expect(named('goal_set'), hasLength(1));
    });

    test('clearing a goal says which kind it was', () async {
      final v = vm();
      await v.load();
      await v.saveGoal(const FitnessGoal(type: GoalType.gainWeight));
      await v.clearGoal();
      expect(named('goal_cleared'), [
        {'type': 'gainWeight'}
      ]);
    });

    test('pinning a muscle is its own event and does not count as a new goal', () async {
      final v = vm();
      await v.load();
      await v.saveGoal(const FitnessGoal(type: GoalType.buildMuscle));
      rec.events.clear();

      await v.setFocus(MuscleGroup.quads, focus: true);
      expect(named('muscle_focus_changed'), [
        {'muscle': 'quads', 'focus': true}
      ]);
      expect(named('goal_set'), isEmpty);
    });

    test('advice is reported as requested, then received', () async {
      remote.nextAdvice = _advice();
      final v = vm();
      await v.load();
      await v.refreshAdvice(force: true);

      expect(named('goal_advice_requested'), [
        {'forced': true}
      ]);
      final got = named('goal_advice_received').single!;
      expect(got['status'], 'onTrack');
      expect(got['actions'], 1);
    });

    test('advice that fails says why, not what it would have said', () async {
      remote.adviceError = BodyTrackingError.rateLimited;
      final v = vm();
      await v.load();
      await v.refreshAdvice();
      expect(named('goal_advice_failed'), [
        {'reason': 'rateLimited'}
      ]);
      expect(named('goal_advice_received'), isEmpty);
    });

    test('no payload carries a weight, a measurement, a note or advice text', () async {
      remote.nextAdvice = _advice();
      final v = vm();
      await v.load();
      await v.logWeight(81.7, note: 'private note');
      await v.logMeasurements({MeasurementSite.waist: 84.2});
      await v.saveGoal(const FitnessGoal(type: GoalType.loseWeight, targetWeightKg: 76.4));
      await v.refreshAdvice();

      final all = rec.events.map((e) => '${e.$1} ${e.$2}').join('\n');
      for (final secret in ['81.7', '84.2', '76.4', 'private note', 'You are on track', 'Keep going']) {
        expect(all.contains(secret), isFalse, reason: secret);
      }
      // And the sanitizer would have kept every property that was sent.
      for (final e in rec.events) {
        expect(AnalyticsSanitizer.clean(e.$2), {for (final k in (e.$2 ?? {}).keys) k: e.$2![k]}, reason: e.$1);
      }
    });
  });
}
