import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_service.dart';
import 'package:fitness/data/services/progression/coach_review_service.dart';
import 'package:fitness/data/services/progression/progression_store.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/progression/progression_engine.dart';
import 'package:fitness/data/services/workout_log/exercise_history_service.dart';
import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/progression/progression_proposal.dart';
import 'package:fitness/domain/use_cases/storage/update_fitness_plan_usecase.dart';
import 'package:fitness/ui/features/progression/view_models/progression_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_storage_repository.dart';
import '../../fakes/recording_analytics.dart';

class _MemoryStore implements ProgressionStore {
  ProgressionSettings settings = const ProgressionSettings();
  final checked = <String, DateTime>{};
  final log = <String, List<AppliedUpdate>>{};

  @override
  Future<ProgressionSettings> loadSettings() async => settings;
  @override
  Future<void> saveSettings(ProgressionSettings s) async => settings = s;
  @override
  Future<DateTime?> lastChecked(String planId) async => checked[planId];
  @override
  Future<void> markChecked(String planId, DateTime at) async => checked[planId] = at;
  @override
  Future<List<AppliedUpdate>> updates(String planId) async => log[planId] ?? [];
  @override
  Future<void> saveUpdates(String planId, List<AppliedUpdate> u) async => log[planId] = u;
}

WorkoutPlanData _data(Exercise bench) => WorkoutPlanData(
      analysisSummary: '',
      physiqueRating: 5,
      goal: 'Build muscle',
      focus: '',
      trainingSplit: 'Push',
      equipment: const [],
      weeklySplit: WeeklySplit(days: [WorkoutDay(day: 'Monday', focus: 'Push', exercises: [bench])]),
      trainingGuidelines: const TrainingGuidelines(
          restBetweenSets: '', progressiveOverload: '', durationWeeks: ''),
      nutritionGuidelines: const NutritionGuidelines(
          proteinPerKg: '', calorieSurplus: '', hydration: '', sleep: ''),
      extraTips: const [],
    );

StoredFitnessPlanEntity _stored(WorkoutPlanData d, {DateTime? createdAt}) => StoredFitnessPlanEntity(
      id: 'p1',
      workoutPlan: WorkoutPlanEntity(plan: d, status: 'success'),
      createdAt: createdAt ?? DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 10, 1),
      isSynced: false,
    );

List<WorkoutSessionModel> _benchSessions(int n, {int reps = 10}) => [
      for (var i = 0; i < n; i++)
        WorkoutSessionModel(
          sessionDate: DateTime(2026, 11, 25).subtract(Duration(days: 1 + 7 * i)),
          workoutLogs: [
            {
              'name': 'Bench Press',
              'sets': 3,
              'reps': '8-10',
              'notes': [for (var s = 1; s <= 3; s++) 'set $s: $reps reps @ 60kg'].join(' | '),
            }
          ],
        ),
    ];

class _FakeCoach implements CoachReviewer {
  CoachResult result = const CoachResult(decisions: {}, reviewed: false);
  Duration delay = Duration.zero;
  Object? error;
  int calls = 0;
  ProgressionProposal? seen;
  GoalType? seenGoal;
  List<MuscleGroup> seenFocus = const [];

  @override
  Future<CoachResult> review(ProgressionProposal proposal,
      {required ProgressionSettings settings, GoalType? goalType, List<MuscleGroup> focus = const []}) async {
    calls++;
    seen = proposal;
    seenGoal = goalType;
    seenFocus = focus;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  final now = DateTime(2026, 11, 25, 9);
  const bench = Exercise(name: 'Bench Press', sets: 3, reps: '8-10', targetKg: 60);

  late _MemoryStore store;
  late FakeStorageRepository repo;
  late List<WorkoutSessionModel>? sessions;

  ProgressionViewModel build() => ProgressionViewModel(
        history: ExerciseHistoryService(fetch: () async => sessions, now: () => now),
        store: store,
        updatePlan: UpdateFitnessPlanUsecase(repo),
        now: () => now,
      );

  setUp(() {
    store = _MemoryStore();
    repo = FakeStorageRepository();
    sessions = _benchSessions(4);
  });

  test('is hidden when there is no plan', () async {
    final vm = build();
    await vm.refresh(plan: null);
    expect(vm.visible, isFalse);
  });

  test('is hidden when the logs could not be read', () async {
    sessions = null;
    final vm = build();
    await vm.refresh(plan: _stored(_data(bench)));
    expect(vm.visible, isFalse);
  });

  test('counts down to the first update while history is thin', () async {
    sessions = _benchSessions(2);
    final vm = build();
    await vm.refresh(plan: _stored(_data(bench)));
    expect(vm.status, ProgressionStatus.building);
    expect(vm.sessionsLeft, 2);
  });

  test('has a proposal ready once there is enough history', () async {
    final vm = build();
    await vm.refresh(plan: _stored(_data(bench)));
    expect(vm.status, ProgressionStatus.ready);
    expect(vm.readyCount, 1);
    expect(vm.proposal!.changes.single.updated!.targetKg, 62.5);
  });

  test('is off when the user turned it off', () async {
    store.settings = const ProgressionSettings(enabled: false);
    final vm = build();
    await vm.refresh(plan: _stored(_data(bench)));
    expect(vm.status, ProgressionStatus.off);
    expect(vm.proposal, isNull);
  });

  test('applying saves the new targets, logs the update and goes quiet', () async {
    final vm = build();
    final plan = _stored(_data(bench));
    repo.seed(plan);
    await vm.refresh(plan: plan);

    expect(await vm.apply(), isTrue);

    final saved = await repo.getFitnessPlanById('p1');
    expect(saved!.workoutPlan.plan.weeklySplit.days.first.exercises.first.targetKg, 62.5);
    expect(vm.status, ProgressionStatus.upToDate);
    expect(vm.updates.single.version, 2);
    expect(vm.updates.single.changeCount, 1);
    expect(vm.updates.single.wasAutomatic, isFalse);
    expect(store.checked['p1'], now);
  });

  test('does not look again until the interval has passed', () async {
    final vm = build();
    final plan = _stored(_data(bench));
    repo.seed(plan);
    await vm.refresh(plan: plan);
    await vm.apply();

    // Same day, plan at its new target and with fresh history at 60 kg:
    // nothing is due.
    await vm.refresh(plan: await repo.getFitnessPlanById('p1'));
    expect(vm.status, ProgressionStatus.upToDate);
    expect(vm.proposal, isNull);
  });

  test('skipping every change applies nothing', () async {
    final vm = build();
    final plan = _stored(_data(bench));
    repo.seed(plan);
    await vm.refresh(plan: plan);
    expect(await vm.apply(skipped: {0}), isFalse);
    expect(vm.updates, isEmpty);
  });

  test('"not this time" waits a full interval before offering again', () async {
    final vm = build();
    final plan = _stored(_data(bench));
    await vm.refresh(plan: plan);
    await vm.dismiss();
    expect(vm.status, ProgressionStatus.upToDate);

    await vm.refresh(plan: plan);
    expect(vm.status, ProgressionStatus.upToDate);
    expect(vm.proposal, isNull);
  });

  test('undo puts the plan back and removes the entry', () async {
    final vm = build();
    final plan = _stored(_data(bench));
    repo.seed(plan);
    await vm.refresh(plan: plan);
    await vm.apply();

    expect(await vm.undo(), isTrue);

    final saved = await repo.getFitnessPlanById('p1');
    expect(saved!.workoutPlan.plan.weeklySplit.days.first.exercises.first.targetKg, 60);
    expect(vm.updates, isEmpty);
  });

  test('applies by itself when the user chose automatic updates', () async {
    store.settings = const ProgressionSettings(mode: ApplyMode.automatic);
    final vm = build();
    final plan = _stored(_data(bench));
    repo.seed(plan);
    await vm.refresh(plan: plan);

    expect(vm.updates.single.wasAutomatic, isTrue);
    expect((await repo.getFitnessPlanById('p1'))!
        .workoutPlan.plan.weeklySplit.days.first.exercises.first.targetKg, 62.5);
  });

  test('proposes an easy week after six weeks, then the return to full load', () async {
    final vm = build();
    final old = _stored(_data(bench), createdAt: DateTime(2026, 9, 1));
    repo.seed(old);
    await vm.refresh(plan: old);
    expect(vm.proposal!.isDeload, isTrue);
    await vm.apply();
    expect(vm.updates.first.isDeload, isTrue);

    // A week later the next update brings the load back.
    final later = ProgressionViewModel(
      history: ExerciseHistoryService(fetch: () async => sessions, now: () => now),
      store: store,
      updatePlan: UpdateFitnessPlanUsecase(repo),
      now: () => now.add(const Duration(days: 8)),
    );
    await later.refresh(plan: await repo.getFitnessPlanById('p1'));
    expect(later.status, ProgressionStatus.ready);
    final back = later.proposal!.changes.first;
    expect(back.reason, contains('Easy week is done'));
    expect(back.updated!.targetKg, 60);
    expect(back.updated!.sets, 3);
  });

  test('saving settings refreshes the state', () async {
    final vm = build();
    final plan = _stored(_data(bench));
    await vm.refresh(plan: plan);
    await vm.saveSettings(const ProgressionSettings(enabled: false));
    expect(vm.status, ProgressionStatus.off);
  });

  group('the coach pass', () {
    late _FakeCoach coach;
    late _MemoryStore store2;
    var allowed = true;
    FitnessGoal? goal;

    ProgressionViewModel coached({Duration timeout = const Duration(seconds: 5)}) => ProgressionViewModel(
          history: ExerciseHistoryService(fetch: () async => sessions, now: () => now),
          store: store2,
          updatePlan: UpdateFitnessPlanUsecase(repo),
          now: () => now,
          coach: coach,
          coachAllowed: () => allowed,
          activeGoal: () async => goal,
          coachTimeout: timeout,
        );

    setUp(() {
      coach = _FakeCoach();
      store2 = _MemoryStore();
      allowed = true;
      goal = null;
    });

    StoredFitnessPlanEntity fresh() => _stored(_data(bench));

    test('reviews a proposal and shows the verdict', () async {
      coach.result = const CoachResult(
        decisions: {'c0': CoachDecision(CoachVerdict.approve, 'Earned it.')},
        note: 'Fine.', reviewed: true,
      );
      final vm = coached();
      await vm.refresh(plan: fresh());
      await pumpEventQueue();

      expect(vm.proposal!.coachState, CoachState.reviewed);
      expect(vm.proposal!.changes.single.coachReason, 'Earned it.');
      expect(vm.proposal!.coachNote, 'Fine.');
    });

    test('shows the proposal at once, as reviewing, then updates', () async {
      coach.delay = const Duration(milliseconds: 50);
      coach.result = const CoachResult(
          decisions: {'c0': CoachDecision(CoachVerdict.soften, 'Smaller.')}, reviewed: true);
      final vm = coached();
      await vm.refresh(plan: fresh());
      expect(vm.status, ProgressionStatus.ready);
      expect(vm.proposal!.coachState, CoachState.reviewing);

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(vm.proposal!.coachState, CoachState.reviewed);
      expect(vm.proposal!.changes.single.updated!.targetKg, 61.5); // 60 + half of 2.5, to 0.5 kg (61.25 rounds up)
    });

    test('is skipped for users without Pro', () async {
      allowed = false;
      final vm = coached();
      await vm.refresh(plan: fresh());
      expect(coach.calls, 0);
      expect(vm.proposal!.coachState, CoachState.off);
    });

    test('a coach that fails leaves the rule engine\'s proposal intact', () async {
      coach.error = Exception('down');
      final vm = coached();
      await vm.refresh(plan: fresh());
      await pumpEventQueue();
      expect(vm.proposal!.coachState, CoachState.unavailable);
      expect(vm.proposal!.changes.single.updated!.targetKg, 62.5);
    });

    test('a coach that is too slow is given up on', () async {
      coach.delay = const Duration(milliseconds: 300);
      final vm = coached(timeout: const Duration(milliseconds: 30));
      await vm.refresh(plan: fresh());
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(vm.proposal!.coachState, CoachState.unavailable);
    });

    test('when the coach holds everything there is nothing to review', () async {
      coach.result = const CoachResult(
          decisions: {'c0': CoachDecision(CoachVerdict.veto, 'Not now.')}, reviewed: true);
      final vm = coached();
      await vm.refresh(plan: fresh());
      await pumpEventQueue();
      expect(vm.proposal, isNull);
      expect(vm.status, ProgressionStatus.upToDate);
      expect(store2.checked['p1'], now);
    });

    test('an applied update carries the coach\'s changes', () async {
      coach.result = const CoachResult(
          decisions: {'c0': CoachDecision(CoachVerdict.soften, 'Smaller.')}, reviewed: true);
      final vm = coached();
      final plan = fresh();
      repo.seed(plan);
      await vm.refresh(plan: plan);
      await pumpEventQueue();
      await vm.apply();
      final saved = await repo.getFitnessPlanById('p1');
      expect(saved!.workoutPlan.plan.weeklySplit.days.first.exercises.first.targetKg, 61.5);
    });

    test('automatic updates wait for the coach before applying', () async {
      store2.settings = const ProgressionSettings(mode: ApplyMode.automatic);
      coach.delay = const Duration(milliseconds: 40);
      coach.result = const CoachResult(
          decisions: {'c0': CoachDecision(CoachVerdict.soften, 'Smaller.')}, reviewed: true);
      final vm = coached();
      final plan = fresh();
      repo.seed(plan);
      await vm.refresh(plan: plan);

      final saved = await repo.getFitnessPlanById('p1');
      expect(saved!.workoutPlan.plan.weeklySplit.days.first.exercises.first.targetKg, 61.5);
      expect(vm.updates.single.wasAutomatic, isTrue);
    });

    test('the body goal and focus muscles are passed on, and shape the proposal', () async {
      goal = const FitnessGoal(type: GoalType.loseWeight, focusMuscles: [MuscleGroup.chest]);
      final vm = coached();
      await vm.refresh(plan: fresh());
      await pumpEventQueue();
      expect(coach.seenGoal, GoalType.loseWeight);
      expect(coach.seenFocus, [MuscleGroup.chest]);
    });

    test('a slow answer for an applied proposal does not resurrect it', () async {
      coach.delay = const Duration(milliseconds: 60);
      coach.result = const CoachResult(
          decisions: {'c0': CoachDecision(CoachVerdict.approve)}, reviewed: true);
      final vm = coached();
      final plan = fresh();
      repo.seed(plan);
      await vm.refresh(plan: plan);
      await vm.apply();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(vm.proposal, isNull);
      expect(vm.status, ProgressionStatus.upToDate);
    });
  });

  group('analytics', () {
    late RecordingAnalytics rec;
    setUp(() {
      rec = RecordingAnalytics();
      Analytics.use(rec);
    });
    tearDown(() => Analytics.use(NoopAnalyticsService()));

    Iterable<Map<String, Object?>?> named(String name) => rec.events.where((e) => e.$1 == name).map((e) => e.$2);

    test('reports a proposal once, however often it is looked at again', () async {
      final vm = build();
      final plan = _stored(_data(bench));
      await vm.refresh(plan: plan);
      await vm.refresh(plan: plan);

      expect(named('plan_update_proposed'), [
        {'changes': 1, 'deload': false}
      ]);
    });

    test('reports an applied update, with how many changes and whether it was automatic', () async {
      final vm = build();
      final plan = _stored(_data(bench));
      repo.seed(plan);
      await vm.refresh(plan: plan);
      await vm.apply();

      expect(named('plan_update_applied'), [
        {'changes': 1, 'skipped': 0, 'automatic': false}
      ]);
    });

    test('an update that applied nothing is not reported as applied', () async {
      final vm = build();
      final plan = _stored(_data(bench));
      repo.seed(plan);
      await vm.refresh(plan: plan);
      await vm.apply(skipped: {0});

      expect(named('plan_update_applied'), isEmpty);
    });

    test('reports "not this time" and undo', () async {
      final vm = build();
      final plan = _stored(_data(bench));
      repo.seed(plan);
      await vm.refresh(plan: plan);
      await vm.dismiss();
      expect(named('plan_update_dismissed'), hasLength(1));

      store.checked.clear();
      await vm.refresh(plan: plan);
      await vm.apply();
      await vm.undo();
      expect(named('plan_update_undone'), hasLength(1));
    });

    test('reports what the coach did, as counts', () async {
      final coach = _FakeCoach()
        ..result = const CoachResult(
            decisions: {'c0': CoachDecision(CoachVerdict.approve, 'Earned it.')}, reviewed: true);
      final vm = ProgressionViewModel(
        history: ExerciseHistoryService(fetch: () async => sessions, now: () => now),
        store: store,
        updatePlan: UpdateFitnessPlanUsecase(repo),
        now: () => now,
        coach: coach,
        coachAllowed: () => true,
        activeGoal: () async => null,
      );
      await vm.refresh(plan: _stored(_data(bench)));
      await pumpEventQueue();

      expect(named('plan_update_coach_reviewed'), [
        {'reviewed': true, 'approved': 1, 'softened': 0, 'held': 0}
      ]);
    });

    test('nothing the coach wrote is in any event', () async {
      final coach = _FakeCoach()
        ..result = const CoachResult(
            decisions: {'c0': CoachDecision(CoachVerdict.approve, 'Secret coach words')},
            note: 'Secret note', reviewed: true);
      final vm = ProgressionViewModel(
        history: ExerciseHistoryService(fetch: () async => sessions, now: () => now),
        store: store,
        updatePlan: UpdateFitnessPlanUsecase(repo),
        now: () => now,
        coach: coach,
        coachAllowed: () => true,
        activeGoal: () async => null,
      );
      await vm.refresh(plan: _stored(_data(bench)));
      await pumpEventQueue();

      final all = rec.events.map((e) => '${e.$1} ${e.$2}').join('\n');
      expect(all.contains('Secret'), isFalse);
      expect(all.contains('Bench'), isFalse);
    });
  });
}
