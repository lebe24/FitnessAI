import 'dart:async';

import 'package:fitness/data/models/onboarding/onboarding_data.dart';
import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_service.dart';
import 'package:fitness/data/services/analytics/exercise_analytics.dart';
import 'package:fitness/data/services/coach/checkin_store.dart';
import 'package:fitness/data/services/coach/exercise_coach_service.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/coach/exercise_recommendation.dart';
import 'package:fitness/domain/coach/session_load.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/progression/progression_engine.dart';
import 'package:fitness/ui/features/fitness/view_models/exercise_coach_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_exercise_coach.dart';
import '../../fakes/recording_analytics.dart';
import 'coach_fixtures.dart';

const _bench = Exercise(name: 'Bench Press', sets: 3, reps: '8-10', targetKg: 60, notes: 'chest, triceps | x');

void main() {
  late FakeExerciseCoach coach;
  late MemoryCheckInStore checkIns;
  late List<WorkoutSessionModel>? sessions;
  FitnessGoal? goal;
  OnboardingData? person;
  var allowed = true;
  var reads = 0;

  ExerciseCoachViewModel vm() => ExerciseCoachViewModel(
        exercise: _bench,
        today: const [_bench],
        sessions: () async {
          reads++;
          return sessions;
        },
        bodyGoal: () async => goal,
        profile: () async => person,
        coach: coach,
        checkIns: checkIns,
        allowed: () => allowed,
        now: () => coachNow,
        analytics: ExerciseAnalytics(_bench, 0),
      );

  setUp(() {
    coach = FakeExerciseCoach();
    checkIns = MemoryCheckInStore();
    sessions = [
      logged(3, {'Bench Press': sets(3, 10, 60)}),
      logged(10, {'Bench Press': sets(3, 10, 60)}),
    ];
    goal = null;
    person = const OnboardingData(goal: 'Build Muscle', experience: 'Experienced', workoutDays: 1);
    allowed = true;
    reads = 0;
  });

  test('works out the numbers and the verdict without calling the model', () async {
    final v = vm();
    await v.load();
    expect(v.recommendation!.action, CoachAction.addWeight);
    expect(v.recommendation!.target.weightKg, 62.5);
    expect(v.session!.verdict, VolumeVerdict.room);
    expect(coach.requests, isEmpty);
  });

  test('a second load while one is running waits for the same one', () async {
    final v = vm();
    final first = v.load();
    await v.load();
    expect(v.recommendation, isNotNull);
    await first;
    expect(reads, 1);
  });

  test('without Pro nothing is read at all', () async {
    allowed = false;
    final v = vm();
    await v.load();
    await v.suggest();
    expect(reads, 0);
    expect(v.recommendation, isNull);
    expect(coach.requests, isEmpty);
  });

  test('says so when the logs cannot be read, instead of advising from nothing', () async {
    sessions = null;
    final v = vm();
    await v.load();
    expect(v.unavailable, isTrue);
    expect(v.recommendation, isNull);
  });

  test('the body goal wins over the onboarding goal', () async {
    goal = const FitnessGoal(type: GoalType.loseWeight);
    final v = vm();
    await v.load();
    expect(v.recommendation!.goal, GoalKind.fatLoss);
  });

  test('"Maintain Gains" is general training, not muscle building', () async {
    person = const OnboardingData(goal: 'Maintain Gains');
    final v = vm();
    await v.load();
    expect(v.recommendation!.goal, GoalKind.general);
    expect(v.session!.volumes[MuscleGroup.chest]!.target, 6);
  });

  test('asking why keeps the coach\'s note', () async {
    final v = vm();
    await v.load();
    await v.askWhy();
    expect(v.why!.note, 'Coach note about this set.');
    expect(coach.requests.single.history.first, startsWith('Nov 23: 3 × 10 @ 60 kg'));
  });

  test('suggest and workout fill their own lists', () async {
    final v = vm();
    await v.load();
    await v.suggest();
    expect(v.suggestions, hasLength(2));
    expect(v.workout, isNull);
    await v.generateWorkout();
    expect(v.workout, hasLength(3));
    expect(v.suggestions, isNull);
  });

  test('a second tap while waiting does nothing', () async {
    coach.gate = Completer<void>();
    final v = vm();
    await v.load();
    final first = v.suggest();
    await v.generateWorkout();
    expect(v.busy, CoachAsk.suggest);
    coach.gate!.complete();
    await first;
    expect(coach.requests, hasLength(1));
    expect(v.busy, isNull);
  });

  test('the check-in is saved, recounts, and clears old suggestions', () async {
    final v = vm();
    await v.load();
    await v.suggest();
    await v.setSoreness(Soreness.verySore);
    expect(v.session!.verdict, VolumeVerdict.stop);
    expect(v.suggestions, isNull);
    expect(await checkIns.read(coachNow), Soreness.verySore);
  });

  test('today\'s check-in is remembered by the next exercise', () async {
    await checkIns.save(coachNow, Soreness.aBitSore);
    final v = vm();
    await v.load();
    expect(v.soreness, Soreness.aBitSore);
  });

  test('an answer that arrives after the check-in changed is dropped', () async {
    coach.gate = Completer<void>();
    final v = vm();
    await v.load();
    final waiting = v.suggest();
    await v.setSoreness(Soreness.verySore);
    coach.gate!.complete();
    await waiting;
    expect(v.suggestions, isNull);
    expect(v.busy, isNull);
  });

  test('added exercises are counted and no longer offered', () async {
    final v = vm();
    await v.load();
    await v.suggest();
    final taken = v.suggestions!.first;
    final before = v.session!.totalSets;
    v.addedToSession([taken.toExercise()], toPlan: false, source: 'suggestion');
    expect(v.session!.totalSets, before + taken.sets);
    expect(v.suggestions!.map((s) => s.exercise.id), isNot(contains(taken.exercise.id)));
  });

  group('analytics', () {
    late RecordingAnalytics rec;
    setUp(() {
      rec = RecordingAnalytics();
      Analytics.use(rec);
    });
    tearDown(() => Analytics.use(NoopAnalyticsService()));

    List<Map<String, Object?>?> named(String n) => [for (final e in rec.events) if (e.$1 == n) e.$2];

    test('reports asks, answers and generated workouts', () async {
      final v = vm();
      await v.load();
      await v.generateWorkout();
      expect(named('exercise_coach_asked').single!['mode'], 'workout');
      expect(named('exercise_coach_received').single!['from_model'], isTrue);
      expect(named('extra_workout_generated'), [
        {'exercises': 3}
      ]);
    });

    test('a failure says why', () async {
      coach.error = ExerciseCoachError.offline;
      final v = vm();
      await v.load();
      await v.suggest();
      expect(named('exercise_coach_failed').single!['reason'], 'offline');
      expect(named('exercise_coach_received'), isEmpty);
    });

    test('no name, weight, soreness answer or coach wording is sent', () async {
      final v = vm();
      await v.load();
      await v.setSoreness(Soreness.verySore);
      await v.askWhy();
      await v.suggest();
      v.addedToSession([v.suggestions!.first.toExercise()], toPlan: true, source: 'suggestion');

      expect(named('session_checkin_answered'), hasLength(1));
      expect(named('extra_exercise_added'), [
        {'count': 1, 'to_plan': true, 'source': 'suggestion'}
      ]);
      final all = rec.events.map((e) => '${e.$1} ${e.$2}').join('\n');
      for (final secret in ['Bench', '62.5', 'verySore', 'very_sore', 'Coach note', 'Fly', 'Pushdown']) {
        expect(all.contains(secret), isFalse, reason: secret);
      }
    });
  });
}
