// Design-review entry point for the exercise page and its coach. Not part of
// the app: sample logs, a scripted coach, and nothing is saved.
//
//   flutter run -t lib/exercise_preview.dart -d <device>
//
// On web, open a state with ?screen=normal|enough|sore|locked|workout|suggest|range
import 'package:fitness/data/models/onboarding/onboarding_data.dart';
import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/billing/complimentary_access.dart';
import 'package:fitness/data/services/billing/paywall_service.dart';
import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:fitness/data/services/coach/checkin_store.dart';
import 'package:fitness/data/services/coach/exercise_coach_service.dart';
import 'package:fitness/data/services/workout_log/exercise_history_service.dart';
import 'package:fitness/data/services/workout_log/workout_log_remote_service.dart';
import 'package:fitness/domain/coach/session_load.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/fitness/view_models/exercise_coach_view_model.dart';
import 'package:fitness/ui/features/fitness/views/exercise_hero_page.dart';
import 'package:flutter/material.dart';

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

class _NoRemote implements WorkoutLogRemoteDataSource {
  @override
  Future<WorkoutSessionModel> saveCompleteSession({
    required DateTime sessionDate,
    required List<Exercise> exercises,
    String? dayLabel,
    String? workoutPlanId,
    int durationMins = 0,
    String? notes,
  }) async =>
      WorkoutSessionModel(sessionDate: sessionDate);

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Answers the way the real coach would, from the same request.
class _ScriptedCoach implements ExerciseCoach {
  @override
  Future<CoachAnswer> ask(ExerciseCoachRequest r) async => CoachAnswer(
        note: 'You have been solid at this weight for two sessions, so the small step up makes sense. '
            'Keep one or two reps in hand on the first set.',
        sessionAdvice: 'Your chest is covered. If you add one thing, make it something that has had less work.',
        picks: r.ask == CoachAsk.workout ? r.candidates.take(3).toList() : r.candidates.take(2).toList(),
        fromModel: true,
      );
}

final _now = DateTime(2025, 11, 20, 17);

WorkoutSessionModel _logged(DateTime date, String name, int reps, num kg) => WorkoutSessionModel(
      sessionDate: date,
      workoutLogs: [
        {
          'name': name,
          'notes': [for (var s = 1; s <= 4; s++) 'set $s: $reps reps @ ${kg}kg'].join(' | '),
        }
      ],
    );

void main() {
  final screen = Uri.base.queryParameters['screen'] ?? 'normal';
  final pro = screen != 'locked';

  final press = Exercise(
    name: 'Incline Dumbbell Press',
    sets: 4,
    reps: screen == 'range' ? '15-20' : '8-10',
    targetKg: 28,
    notes: 'chest, shoulders, triceps | Keep your shoulder blades pinned back and stop short of locking out at the top.',
  );
  final today = [
    press,
    const Exercise(name: 'Lat Pulldown', sets: 3, reps: '10', notes: 'back, biceps | Elbows down.'),
    if (screen == 'enough') ...const [
      Exercise(name: 'Cable Fly', sets: 4, reps: '12', notes: 'chest | Squeeze.'),
      Exercise(name: 'Bench Press', sets: 4, reps: '8', notes: 'chest, triceps | Brace.'),
    ],
  ];

  final subs = _Subs(pro);
  sl
    ..registerSingleton<AccessPolicy>(AccessPolicy(subs, _NoComp()))
    ..registerSingleton<PaywallService>(_Paywall(subs))
    ..registerSingleton<WorkoutLogRemoteDataSource>(_NoRemote());
  final history = ExerciseHistoryService(
    fetch: () async => [
      _logged(DateTime(2025, 11, 18), press.name, 10, 28),
      _logged(DateTime(2025, 11, 11), press.name, 10, 28),
      _logged(DateTime(2025, 11, 4), press.name, 10, 26),
    ],
    now: () => _now,
  );
  sl.registerSingleton<ExerciseHistoryService>(history);

  final checkIns = MemoryCheckInStore();
  if (screen == 'sore') checkIns.save(_now, Soreness.verySore);

  final coach = ExerciseCoachViewModel(
    exercise: press,
    today: today,
    sessions: () => history.sessions(),
    bodyGoal: () async => null,
    profile: () async => const OnboardingData(goal: 'Build Muscle', experience: 'Experienced', workoutDays: 1),
    coach: _ScriptedCoach(),
    checkIns: checkIns,
    allowed: () => pro,
    now: () => _now,
  );
  if (screen == 'workout' || screen == 'suggest') {
    coach.load().then((_) async {
      await coach.askWhy();
      screen == 'workout' ? await coach.generateWorkout() : await coach.suggest();
    });
  }

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: kBodyBg),
    builder: (context, child) => ColoredBox(
      color: kBodyBg,
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 390), child: child)),
    ),
    home: ExerciseHeroPage(
      exercise: press,
      exerciseIndex: 0,
      sessionExercises: today,
      coach: coach,
      onComplete: () {},
      onAddExercises: (list, {required toPlan}) async =>
          toPlan ? ExerciseAddOutcome.todayAndPlan : ExerciseAddOutcome.today,
      canAddToPlan: () async => true,
    ),
  ));
}
