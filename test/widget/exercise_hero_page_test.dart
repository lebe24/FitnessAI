import 'package:fitness/data/models/onboarding/onboarding_data.dart';
import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/billing/complimentary_access.dart';
import 'package:fitness/data/services/billing/paywall_service.dart';
import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:fitness/data/services/coach/checkin_store.dart';
import 'package:fitness/data/services/workout_log/exercise_history_service.dart';
import 'package:fitness/data/services/workout_log/workout_draft_storage.dart';
import 'package:fitness/data/services/workout_log/workout_log_remote_service.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:fitness/ui/features/fitness/view_models/exercise_coach_view_model.dart';
import 'package:fitness/ui/features/fitness/views/exercise_detail/detail_widgets.dart';
import 'package:fitness/ui/features/fitness/views/exercise_hero_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../fakes/fake_exercise_coach.dart';
import '../unit/coach/coach_fixtures.dart';

const _bench = Exercise(
  name: 'Bench Press',
  sets: 3,
  reps: '8-10',
  targetKg: 60,
  notes: 'chest, triceps | Keep your shoulder blades pinned back.',
);

class _Subs extends SubscriptionService {
  final bool pro;
  _Subs(this.pro);
  @override
  bool get isPro => pro;
}

class _NoComp extends ComplimentaryAccess {
  _NoComp();
  @override
  bool get isGranted => false;
}

class _Paywall extends PaywallService {
  _Paywall(super.subs);
  @override
  Future<bool> present({String? offeringIdentifier, String source = 'unknown'}) async => false;
}

class _Remote implements WorkoutLogRemoteDataSource {
  final saved = <List<Exercise>>[];

  @override
  Future<WorkoutSessionModel> saveCompleteSession({
    required DateTime sessionDate,
    required List<Exercise> exercises,
    String? dayLabel,
    String? workoutPlanId,
    int durationMins = 0,
    String? notes,
  }) async {
    saved.add(exercises);
    return WorkoutSessionModel(sessionDate: sessionDate);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Run {
  final coach = FakeExerciseCoach();
  final remote = _Remote();
  final added = <(List<Exercise>, bool)>[];
  var completed = 0;
  var sessionReads = 0;
}

Future<_Run> _open(
  WidgetTester t, {
  bool pro = true,
  bool canAdd = true,
  bool planMatches = true,
  double width = 390,
  ExerciseAddOutcome? outcome,
}) async {
  final run = _Run();
  await sl.reset();
  final subs = _Subs(pro);
  sl.registerSingleton<AccessPolicy>(AccessPolicy(subs, _NoComp()));
  sl.registerSingleton<PaywallService>(_Paywall(subs));
  sl.registerSingleton<WorkoutLogRemoteDataSource>(run.remote);
  final sessions = [
    logged(3, {'Bench Press': sets(3, 10, 60)}),
    logged(10, {'Bench Press': sets(3, 10, 60)}),
    logged(17, {'Bench Press': sets(3, 10, 57.5)}),
  ];
  final history = ExerciseHistoryService(
    fetch: () async {
      run.sessionReads++;
      return sessions;
    },
    now: () => coachNow,
  );
  sl.registerSingleton<ExerciseHistoryService>(history);

  final coach = ExerciseCoachViewModel(
    exercise: _bench,
    today: const [_bench],
    sessions: () => history.sessions(),
    bodyGoal: () async => null,
    profile: () async => const OnboardingData(goal: 'Build Muscle', experience: 'Experienced'),
    coach: run.coach,
    checkIns: MemoryCheckInStore(),
    allowed: () => pro,
    now: () => coachNow,
  );

  t.view.physicalSize = Size(width, 3200);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ExerciseHeroPage(
              exercise: _bench,
              exerciseIndex: 0,
              sessionExercises: const [_bench],
              coach: coach,
              onComplete: () => run.completed++,
              onAddExercises: canAdd
                  ? (list, {required toPlan}) async {
                      run.added.add((list, toPlan));
                      return outcome ?? (toPlan ? ExerciseAddOutcome.todayAndPlan : ExerciseAddOutcome.today);
                    }
                  : null,
              canAddToPlan: () async => planMatches,
            ),
          )),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
  return run;
}

List<String> _fields(WidgetTester t) =>
    t.widgetList<TextField>(find.byType(TextField)).map((f) => f.controller!.text).toList();

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() async => sl.reset());

  group('the design', () {
    testWidgets('name, muscles, figures and the plan cue as the safety tip', (t) async {
      await _open(t);
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Chest'), findsWidgets);
      expect(find.text('Triceps'), findsWidgets);
      for (final label in ['Sets', 'Reps', 'Last weight']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('60 kg'), findsOneWidget);
      expect(find.text('Plan target 60 kg · Tap to log your sets'), findsOneWidget);
      expect(find.text('Safety tip'), findsOneWidget);
      expect(find.text('Keep your shoulder blades pinned back.'), findsOneWidget);
      expect(find.text('Tutorials'), findsOneWidget);
      expect(find.text('Complete exercise'), findsOneWidget);
    });

    testWidgets('history is one line per visit', (t) async {
      await _open(t);
      expect(find.text('Nov 23'), findsOneWidget);
      expect(find.text('Nov 16'), findsOneWidget);
      expect(find.text('3 × 10 @ 60 kg'), findsNWidgets(2));
      expect(find.text('Nov 9'), findsOneWidget);
      expect(find.text('3 × 10 @ 57.5 kg'), findsOneWidget);
    });

    testWidgets('the tip falls back when the notes hold no cue', (t) async {
      expect(SafetyTipCard.tipFor(null), SafetyTipCard.fallback);
      expect(SafetyTipCard.tipFor('chest'), SafetyTipCard.fallback);
      expect(SafetyTipCard.tipFor('set 1: 10 reps @ 60kg | set 2: 8 reps @ 60kg'), SafetyTipCard.fallback);
      expect(SafetyTipCard.tipFor('chest | Brace.'), 'Brace.');
    });

    testWidgets('does not overflow on a narrow phone', (t) async {
      await _open(t, width: 320);
      await t.tap(find.text('Suggest an exercise'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('technique notes are in the menu', (t) async {
      await _open(t);
      await t.tap(find.bySemanticsLabel('More options'));
      await t.pumpAndSettle();
      expect(find.text('Full history'), findsOneWidget);
      expect(find.text('Add an exercise'), findsOneWidget);
      await t.tap(find.text('Technique notes'));
      await t.pumpAndSettle();
      expect(find.text(_bench.notes!), findsOneWidget);
    });
  });

  group('logging still works as before', () {
    testWidgets('tapping the figures opens the log; saving sends the sets', (t) async {
      final run = await _open(t);
      await t.tap(find.text('Sets'));
      await t.pumpAndSettle();
      expect(find.text('Save log'), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await t.enterText(find.byType(TextField).at(i * 2), '60');
        await t.enterText(find.byType(TextField).at(i * 2 + 1), '9');
      }
      await t.tap(find.text('Save log'));
      await t.pumpAndSettle();

      expect(run.remote.saved.single.single.notes,
          'set 1: 9 reps @ 60kg | set 2: 9 reps @ 60kg | set 3: 9 reps @ 60kg');
    });

    testWidgets('leaving with typed sets asks first', (t) async {
      await _open(t);
      await t.tap(find.text('Sets'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, '60');
      // Close the dialog without saving.
      await t.tapAt(const Offset(2, 2));
      await t.pumpAndSettle();

      await t.tap(find.bySemanticsLabel('Back'));
      await t.pumpAndSettle();
      expect(find.text('Save before leaving?'), findsOneWidget);
      await t.tap(find.text('Discard'));
      await t.pumpAndSettle();
      expect(find.byType(ExerciseHeroPage), findsNothing);
    });

    testWidgets('leaving with nothing typed just leaves', (t) async {
      await _open(t);
      await t.tap(find.bySemanticsLabel('Back'));
      await t.pumpAndSettle();
      expect(find.byType(ExerciseHeroPage), findsNothing);
    });

    testWidgets('Complete exercise tells the workout', (t) async {
      final run = await _open(t);
      await t.tap(find.text('Complete exercise'));
      expect(run.completed, 1);
    });
  });

  group('the coach', () {
    testWidgets('shows the recommendation without calling the model', (t) async {
      final run = await _open(t);
      expect(find.text('3 × 8-10 @ 62.5 kg'), findsOneWidget);
      expect(find.text('+2.5 kg'), findsOneWidget);
      expect(run.coach.requests, isEmpty);
    });

    testWidgets('Use this fills the log with the recommended numbers', (t) async {
      await _open(t);
      await t.tap(find.text('Use this'));
      await t.pumpAndSettle();
      expect(find.text('Save log'), findsOneWidget);
      expect(_fields(t), ['62.5', '8-10', '62.5', '8-10', '62.5', '8-10']);
    });

    testWidgets('Ask the coach shows its note and where it came from', (t) async {
      await _open(t);
      await t.tap(find.text('Ask the coach'));
      await t.pumpAndSettle();
      expect(find.text('Coach note about this set.'), findsOneWidget);
      expect(find.text('Written by your AI coach'), findsOneWidget);
      expect(find.text('Ask again'), findsOneWidget);
    });

    testWidgets('the session card counts today and offers more', (t) async {
      await _open(t);
      expect(find.text('Today\'s session'), findsOneWidget);
      expect(find.text('Room for a bit more'), findsOneWidget);
      expect(find.text('3 sets today'), findsOneWidget);
      expect(find.text('Suggest an exercise'), findsOneWidget);
      expect(find.text('Generate extra workout'), findsOneWidget);
    });

    testWidgets('very sore says stop but still lets you carry on', (t) async {
      await _open(t);
      await t.tap(find.text('Very sore'));
      await t.pumpAndSettle();
      expect(find.text('Call it here'), findsOneWidget);
      expect(find.text('Want to do more anyway?'), findsOneWidget);

      await t.tap(find.text('Suggest an exercise'));
      await t.pumpAndSettle();
      expect(find.text('Add'), findsNWidgets(2));
    });

    testWidgets('a suggestion can be added just for today', (t) async {
      final run = await _open(t);
      await t.tap(find.text('Suggest an exercise'));
      await t.pumpAndSettle();
      expect(find.text('Coach advice about the session.'), findsOneWidget);
      await t.tap(find.text('Add').first);
      await t.pumpAndSettle();
      await t.tap(find.text('Just today'));
      await t.pumpAndSettle();

      expect(run.added.single.$1, hasLength(1));
      expect(run.added.single.$2, isFalse);
      expect(find.textContaining('to today\'s workout.'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget); // the added one has gone
    });

    testWidgets('or to the plan as well', (t) async {
      final run = await _open(t);
      await t.tap(find.text('Suggest an exercise'));
      await t.pumpAndSettle();
      await t.tap(find.text('Add').first);
      await t.pumpAndSettle();
      await t.tap(find.text('Also add to my plan'));
      await t.pumpAndSettle();
      expect(run.added.single.$2, isTrue);
      expect(find.textContaining('to today and to your plan.'), findsOneWidget);
    });

    testWidgets('the plan choice is off when this is not a plan day', (t) async {
      final run = await _open(t, planMatches: false);
      await t.tap(find.text('Suggest an exercise'));
      await t.pumpAndSettle();
      await t.tap(find.text('Add').first);
      await t.pumpAndSettle();
      expect(find.text('This workout is not a day in your saved plan.'), findsOneWidget);
      await t.tap(find.text('Also add to my plan'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(run.added, isEmpty);
    });

    testWidgets('a plan that could not be saved is reported', (t) async {
      await _open(t, outcome: ExerciseAddOutcome.planFailed);
      await t.tap(find.text('Suggest an exercise'));
      await t.pumpAndSettle();
      await t.tap(find.text('Add').first);
      await t.pumpAndSettle();
      await t.tap(find.text('Also add to my plan'));
      await t.pumpAndSettle();
      expect(find.textContaining('your plan could not be saved'), findsOneWidget);
    });

    testWidgets('dismissing the choice adds nothing', (t) async {
      final run = await _open(t);
      await t.tap(find.text('Suggest an exercise'));
      await t.pumpAndSettle();
      await t.tap(find.text('Add').first);
      await t.pumpAndSettle();
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
      expect(run.added, isEmpty);
    });

    testWidgets('a generated workout is added all at once', (t) async {
      final run = await _open(t);
      await t.tap(find.text('Generate extra workout'));
      await t.pumpAndSettle();
      expect(find.text('Extra workout'), findsOneWidget);
      await t.tap(find.text('Add all 3'));
      await t.pumpAndSettle();
      expect(find.text('Add 3 exercises?'), findsOneWidget);
      await t.tap(find.text('Just today'));
      await t.pumpAndSettle();
      expect(run.added.single.$1, hasLength(3));
    });

    testWidgets('suggestions have no add button when the page cannot add', (t) async {
      await _open(t, canAdd: false);
      await t.tap(find.text('Suggest an exercise'));
      await t.pumpAndSettle();
      expect(find.text('Suggestions'), findsOneWidget);
      expect(find.text('Add'), findsNothing);
    });
  });

  group('free users', () {
    testWidgets('see locked cards, and nothing is read or sent', (t) async {
      final run = await _open(t, pro: false);
      expect(find.byType(PremiumLockedCard), findsWidgets);
      expect(find.text('Get coached on every set'), findsOneWidget);
      // The last weight is a lock, not a number.
      expect(find.descendant(of: find.byType(DetailStats), matching: find.byIcon(Icons.lock_outline_rounded)),
          findsOneWidget);
      expect(find.text('60 kg'), findsNothing);
      expect(find.text('Today\'s session'), findsNothing);
      expect(run.sessionReads, 0);
      expect(run.coach.requests, isEmpty);
    });

    testWidgets('can still log and complete', (t) async {
      final run = await _open(t, pro: false);
      await t.tap(find.text('Sets'));
      await t.pumpAndSettle();
      expect(find.text('Save log'), findsOneWidget);
      await t.tapAt(const Offset(2, 2));
      await t.pumpAndSettle();
      await t.tap(find.text('Complete exercise'));
      expect(run.completed, 1);
    });
  });

  group('the draft', () {
    testWidgets('typing in the log publishes the sets to the workout', (t) async {
      final published = <List<DraftSet>>[];
      await sl.reset();
      final subs = _Subs(false);
      sl.registerSingleton<AccessPolicy>(AccessPolicy(subs, _NoComp()));
      sl.registerSingleton<PaywallService>(_Paywall(subs));
      sl.registerSingleton<ExerciseHistoryService>(ExerciseHistoryService(fetch: () async => const []));
      t.view.physicalSize = const Size(390, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        home: ExerciseHeroPage(
          exercise: _bench,
          exerciseIndex: 0,
          onComplete: () {},
          onSetsChanged: published.add,
          coach: ExerciseCoachViewModel(
            exercise: _bench,
            today: const [_bench],
            sessions: () async => const [],
            bodyGoal: () async => null,
            profile: () async => null,
            coach: FakeExerciseCoach(),
            checkIns: MemoryCheckInStore(),
            allowed: () => false,
          ),
        ),
      ));
      await t.pumpAndSettle();
      await t.tap(find.text('Sets'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, '42');
      expect(published.last.first.weight, '42');
    });
  });
}
