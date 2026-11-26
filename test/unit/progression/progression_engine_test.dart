import 'package:fitness/data/models/home/workout_plan_model.dart';
import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/progression/progression_engine.dart';
import 'package:fitness/domain/progression/progression_proposal.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 25, 9);

WorkoutPlanData _plan(List<Exercise> exercises, {String goal = 'Build muscle'}) => WorkoutPlanData(
      analysisSummary: '',
      physiqueRating: 5,
      goal: goal,
      focus: '',
      trainingSplit: 'Push',
      equipment: const [],
      weeklySplit: WeeklySplit(days: [WorkoutDay(day: 'Monday', focus: 'Push', exercises: exercises)]),
      trainingGuidelines: const TrainingGuidelines(
          restBetweenSets: '', progressiveOverload: '', durationWeeks: ''),
      nutritionGuidelines: const NutritionGuidelines(
          proteinPerKg: '', calorieSurplus: '', hydration: '', sleep: ''),
      extraTips: const [],
    );

/// One logged exercise as the session blob stores it.
Map<String, dynamic> _log(String name, String sets) =>
    {'name': name, 'sets': 3, 'reps': '8', 'notes': sets};

/// Sessions on the given days ago, newest first, each logging [perSession]
/// for the exercise [name].
List<WorkoutSessionModel> _sessions(String name, List<String> perSession,
    {List<int>? daysAgo}) {
  final days = daysAgo ?? [1, 8, 15, 22, 29, 36].sublist(0, perSession.length);
  return [
    for (var i = 0; i < perSession.length; i++)
      WorkoutSessionModel(
        sessionDate: DateTime(2026, 11, 25).subtract(Duration(days: days[i])),
        workoutLogs: [_log(name, perSession[i])],
      ),
  ];
}

String _sets(int n, int reps, num kg) =>
    [for (var i = 1; i <= n; i++) 'set $i: $reps reps @ ${kg}kg'].join(' | ');

ProgressionProposal? _propose(
  WorkoutPlanData plan,
  List<WorkoutSessionModel> sessions, {
  ProgressionSettings settings = const ProgressionSettings(),
  bool deloadDue = false,
}) =>
    ProgressionEngine.propose(
      plan: plan,
      sessions: sessions,
      settings: settings,
      now: _now,
      fromVersion: 1,
      deloadDue: deloadDue,
    );

PlannedChange _only(ProgressionProposal p) => p.changes.single;

void main() {
  group('goal', () {
    test('is read from the plan text', () {
      expect(goalKindOf('Build Muscle'), GoalKind.hypertrophy);
      expect(goalKindOf('Lose fat'), GoalKind.fatLoss);
      expect(goalKindOf('Get stronger'), GoalKind.strength);
      expect(goalKindOf('General Fitness'), GoalKind.general);
    });
  });

  group('when there is too little to go on', () {
    test('proposes nothing before enough sessions are logged', () {
      final plan = _plan([const Exercise(name: 'Bench Press', sets: 3, reps: '8-10', targetKg: 60)]);
      final s = _sessions('Bench Press', [_sets(3, 10, 60), _sets(3, 10, 60), _sets(3, 10, 60)]);
      expect(ProgressionEngine.sessionsInWindow(s, _now), 3);
      expect(_propose(plan, s), isNull);
    });

    test('proposes nothing for an exercise that was never logged', () {
      final plan = _plan([const Exercise(name: 'Cable Fly', sets: 3, reps: '10-12')]);
      final s = _sessions('Bench Press', List.filled(4, _sets(3, 10, 60)));
      expect(_propose(plan, s), isNull);
    });

    test('ignores sessions older than the window', () {
      final s = _sessions('Bench Press', List.filled(4, _sets(3, 10, 60)),
          daysAgo: [50, 57, 64, 71]);
      expect(ProgressionEngine.sessionsInWindow(s, _now), 0);
    });
  });

  group('adding weight', () {
    final plan = _plan([const Exercise(name: 'Bench Press', sets: 3, reps: '8-10', targetKg: 60)]);

    test('after two sessions at the top of the range', () {
      final s = _sessions('Bench Press', List.filled(4, _sets(3, 10, 60)));
      final c = _only(_propose(plan, s)!);
      expect(c.kind, ChangeKind.load);
      expect(c.badge, '+2.5 kg');
      expect(c.updated!.targetKg, 62.5);
      expect(c.before, '3 × 8-10 · 60 kg');
      expect(c.after, '3 × 8-10 · 62.5 kg');
      expect(c.reason, contains('last 4 sessions'));
    });

    test('not after only one', () {
      final s = _sessions('Bench Press', [
        _sets(3, 10, 60), _sets(3, 9, 60), _sets(3, 9, 60), _sets(3, 8, 60),
      ]);
      expect(_propose(plan, s), isNull);
    });

    test('lower-body lifts go up by 5 kg', () {
      final squat = _plan([const Exercise(name: 'Back Squat', sets: 4, reps: '6-8', targetKg: 80)]);
      final s = _sessions('Back Squat', List.filled(4, _sets(4, 8, 80)));
      expect(_only(_propose(squat, s)!).updated!.targetKg, 85);
    });

    test('small dumbbells go up by 1 kg', () {
      final curl = _plan([const Exercise(name: 'Hammer Curl', sets: 3, reps: '10-12', targetKg: 12)]);
      final s = _sessions('Hammer Curl', List.filled(4, _sets(3, 12, 12)));
      expect(_only(_propose(curl, s)!).updated!.targetKg, 13);
    });

    test('a steady pace asks for three sessions, an ambitious one for one', () {
      final two = _sessions('Bench Press', [
        _sets(3, 10, 60), _sets(3, 10, 60), _sets(3, 9, 60), _sets(3, 9, 60),
      ]);
      expect(
          _propose(plan, two, settings: const ProgressionSettings(pace: ProgressionPace.steady)),
          isNull);
      final one = _sessions('Bench Press', [
        _sets(3, 10, 60), _sets(3, 9, 60), _sets(3, 9, 60), _sets(3, 9, 60),
      ]);
      final fast = _propose(plan, one,
          settings: const ProgressionSettings(pace: ProgressionPace.ambitious))!;
      expect(_only(fast).kind, ChangeKind.load);
    });

    test('uses the last working weight when the plan has no target yet', () {
      final legacy = _plan([const Exercise(name: 'Bench Press', sets: 3, reps: '8-10')]);
      final s = _sessions('Bench Press', List.filled(4, _sets(3, 10, 65)));
      final c = _only(_propose(legacy, s)!);
      expect(c.before, '3 × 8-10 · 65 kg');
      expect(c.updated!.targetKg, 67.5);
    });

    test('sessions below the new target do not count toward the next rise', () {
      final raised = _plan([const Exercise(name: 'Bench Press', sets: 3, reps: '8-10', targetKg: 62.5)]);
      // Only one session at 62.5; the older ones were at 60.
      final s = _sessions('Bench Press', [
        _sets(3, 10, 62.5), _sets(3, 10, 60), _sets(3, 10, 60), _sets(3, 10, 60),
      ]);
      expect(_propose(raised, s), isNull);
    });

    test('warm-up sets do not count against the rep target', () {
      final s = _sessions('Bench Press', List.filled(4,
          'set 1: 5 reps @ 30kg | ${_sets(3, 10, 60)}'.replaceFirst('set 1: 10 reps @ 60kg', 'set 2: 10 reps @ 60kg')));
      expect(_only(_propose(plan, s)!).kind, ChangeKind.load);
    });
  });

  group('reps before weight', () {
    test('a fixed rep target goes up by one', () {
      final plan = _plan([const Exercise(name: 'Incline Dumbbell Press', sets: 3, reps: '8', targetKg: 22)]);
      final s = _sessions('Incline Dumbbell Press', List.filled(4, _sets(3, 8, 22)));
      final c = _only(_propose(plan, s)!);
      expect(c.kind, ChangeKind.reps);
      expect(c.updated!.reps, '9');
      expect(c.updated!.targetKg, 22);
      expect(c.after, '3 × 9 · 22 kg');
    });

    test('a strength plan skips straight to weight at 6 reps', () {
      final plan = _plan([const Exercise(name: 'Back Squat', sets: 5, reps: '5', targetKg: 100)],
          goal: 'Get stronger');
      final s = _sessions('Back Squat', List.filled(4, _sets(5, 5, 100)));
      expect(_only(_propose(plan, s)!).kind, ChangeKind.reps);
      final six = _plan([const Exercise(name: 'Back Squat', sets: 5, reps: '6', targetKg: 100)],
          goal: 'Get stronger');
      final s6 = _sessions('Back Squat', List.filled(4, _sets(5, 6, 100)));
      expect(_only(_propose(six, s6)!).kind, ChangeKind.load);
    });

    test('bodyweight work raises the rep range by two', () {
      final plan = _plan([const Exercise(name: 'Push-Ups', sets: 3, reps: '10-12')]);
      final s = _sessions('Push-Ups',
          List.filled(4, [for (var i = 1; i <= 3; i++) 'set $i: 12 reps'].join(' | ')));
      final c = _only(_propose(plan, s)!);
      expect(c.updated!.reps, '12-14');
      expect(c.badge, '+2 reps');
    });
  });

  group('holding and stalls', () {
    test('holds an exercise whose last session missed a set', () {
      final plan = _plan([
        const Exercise(name: 'Bench Press', sets: 3, reps: '8-10', targetKg: 60),
        const Exercise(name: 'Lat Pulldown', sets: 3, reps: '10', targetKg: 50),
      ]);
      final s = [
        ..._sessions('Bench Press', List.filled(4, _sets(3, 10, 60))),
        ..._sessions('Lat Pulldown', [
          'set 1: 10 reps @ 50kg | set 2: 10 reps @ 50kg | set 3: 6 reps @ 50kg',
          _sets(3, 10, 50), _sets(3, 10, 50), _sets(3, 10, 50)
        ]),
      ];
      final p = _propose(plan, s)!;
      final hold = p.changes.firstWhere((c) => c.exercise == 'Lat Pulldown');
      expect(hold.kind, ChangeKind.hold);
      expect(hold.reason, contains('Set 3 fell to 6 reps'));
      expect(p.holdCount, 1);
    });

    test('a hold alone is not an update', () {
      final plan = _plan([const Exercise(name: 'Lat Pulldown', sets: 3, reps: '10', targetKg: 50)]);
      final s = _sessions('Lat Pulldown', [
        'set 1: 10 reps @ 50kg | set 2: 6 reps @ 50kg | set 3: 6 reps @ 50kg',
        _sets(3, 10, 50), _sets(3, 10, 50), _sets(3, 10, 50),
      ]);
      expect(_propose(plan, s), isNull);
    });

    test('drops the load by 10% after three sessions without progress', () {
      final plan = _plan([const Exercise(name: 'Walking Lunges', sets: 3, reps: '10', targetKg: 20)]);
      final s = _sessions('Walking Lunges', [
        'set 1: 10 reps @ 20kg | set 2: 8 reps @ 20kg | set 3: 7 reps @ 20kg',
        'set 1: 10 reps @ 20kg | set 2: 9 reps @ 20kg | set 3: 8 reps @ 20kg',
        'set 1: 10 reps @ 20kg | set 2: 9 reps @ 20kg | set 3: 9 reps @ 20kg',
        _sets(3, 10, 20),
      ]);
      final c = _only(_propose(plan, s)!);
      expect(c.kind, ChangeKind.deload);
      expect(c.updated!.targetKg, 18);
      expect(c.badge, '−10%');
    });

    test('does not call it a stall while the numbers are still improving', () {
      final plan = _plan([const Exercise(name: 'Walking Lunges', sets: 3, reps: '10', targetKg: 20)]);
      final s = _sessions('Walking Lunges', [
        'set 1: 10 reps @ 22kg | set 2: 8 reps @ 22kg | set 3: 7 reps @ 22kg',
        _sets(3, 10, 20), _sets(3, 10, 20), _sets(3, 10, 20),
      ]);
      final p = _propose(plan, s);
      expect(p?.changes.where((c) => c.kind == ChangeKind.deload) ?? const [], isEmpty);
    });
  });

  group('extra volume', () {
    final plan = _plan([const Exercise(name: 'Lateral Raise', sets: 3, reps: '12-15', targetKg: 8)]);
    final s = _sessions('Lateral Raise', [
      'set 1: 14 reps @ 8kg | set 2: 13 reps @ 8kg | set 3: 12 reps @ 8kg',
      'set 1: 14 reps @ 8kg | set 2: 13 reps @ 8kg | set 3: 12 reps @ 8kg',
      'set 1: 14 reps @ 8kg | set 2: 13 reps @ 8kg | set 3: 12 reps @ 8kg',
      'set 1: 13 reps @ 8kg | set 2: 12 reps @ 8kg | set 3: 12 reps @ 8kg',
    ]);

    test('a fourth set for a comfortable isolation lift when building muscle', () {
      // 4 sessions of a 1-day plan is 4 / 6 planned: low attendance blocks it.
      expect(_propose(plan, s), isNull);
      final busy = _plan([
        const Exercise(name: 'Lateral Raise', sets: 3, reps: '12-15', targetKg: 8)
      ]);
      // Attendance counts every day of the plan; fake a one-day plan trained
      // far more often than weekly by adding sessions inside the window.
      final many = [
        ...s,
        ..._sessions('Lateral Raise', List.filled(2, _sets(3, 13, 8)), daysAgo: [3, 5]),
      ];
      final c = _only(_propose(busy, many)!);
      expect(c.kind, ChangeKind.sets);
      expect(c.updated!.sets, 4);
    });

    test('never for strength training', () {
      final strength = _plan([const Exercise(name: 'Lateral Raise', sets: 3, reps: '12-15', targetKg: 8)],
          goal: 'Get stronger');
      final many = [
        ...s,
        ..._sessions('Lateral Raise', List.filled(2, _sets(3, 13, 8)), daysAgo: [3, 5]),
      ];
      expect(_propose(strength, many), isNull);
    });
  });

  group('exercises the rules cannot judge', () {
    test('timed holds are left alone', () {
      final plan = _plan([const Exercise(name: 'Plank', sets: 3, reps: '45 sec')]);
      final s = _sessions('Plank',
          List.filled(4, 'set 1: 45 sec | set 2: 45 sec | set 3: 45 sec'));
      expect(_propose(plan, s), isNull);
    });
  });

  group('easy weeks', () {
    final plan = _plan([
      const Exercise(name: 'Bench Press', sets: 3, reps: '8-10', targetKg: 62.5),
      const Exercise(name: 'Push-Ups', sets: 3, reps: '12'),
    ]);
    final s = [
      ..._sessions('Bench Press', List.filled(4, _sets(3, 9, 62.5))),
      ..._sessions('Push-Ups', List.filled(4, 'set 1: 12 reps | set 2: 12 reps | set 3: 12 reps')),
    ];

    test('lighter load and one set fewer', () {
      final p = _propose(plan, s, deloadDue: true)!;
      expect(p.isDeload, isTrue);
      final bench = p.changes.firstWhere((c) => c.exercise == 'Bench Press');
      expect(bench.updated!.targetKg, 56.5);
      expect(bench.updated!.sets, 2);
      final push = p.changes.firstWhere((c) => c.exercise == 'Push-Ups');
      expect(push.updated!.sets, 2);
      expect(push.badge, '−1 set');
    });

    test('resume restores what the easy week lowered', () {
      final p = _propose(plan, s, deloadDue: true)!;
      final lowered = ProgressionEngine.apply(plan, p);
      final back = ProgressionEngine.resume(
        plan: lowered,
        before: plan.weeklySplit,
        fromVersion: 2,
        sessionsAnalysed: 8,
        adherence: 0.9,
      )!;
      final restored = ProgressionEngine.apply(lowered, back);
      expect(restored.weeklySplit.days.first.exercises.map((e) => (e.sets, e.targetKg)),
          plan.weeklySplit.days.first.exercises.map((e) => (e.sets, e.targetKg)));
    });
  });

  group('applying a proposal', () {
    final plan = _plan([
      const Exercise(name: 'Bench Press', sets: 3, reps: '8-10', targetKg: 60),
      const Exercise(name: 'Row', sets: 3, reps: '8-10', targetKg: 50),
    ]);
    final s = [
      ..._sessions('Bench Press', List.filled(4, _sets(3, 10, 60))),
      ..._sessions('Row', List.filled(4, _sets(3, 10, 50))),
    ];

    test('changes the targets and nothing else', () {
      final p = _propose(plan, s)!;
      final next = ProgressionEngine.apply(plan, p);
      final ex = next.weeklySplit.days.first.exercises;
      expect(ex.map((e) => e.targetKg), [62.5, 52.5]);
      expect(ex.map((e) => e.name), ['Bench Press', 'Row']);
      expect(next.goal, plan.goal);
      expect(next.weeklySplit.days.first.day, 'Monday');
    });

    test('leaves out the changes the user skipped', () {
      final p = _propose(plan, s)!;
      final skip = {p.changes.indexWhere((c) => c.exercise == 'Row')};
      final next = ProgressionEngine.apply(plan, p, skipped: skip);
      expect(next.weeklySplit.days.first.exercises.map((e) => e.targetKg), [62.5, 50]);
    });

    test('does not touch an exercise that has moved since the proposal', () {
      final p = _propose(plan, s)!;
      final reordered = _plan([plan.weeklySplit.days.first.exercises[1], plan.weeklySplit.days.first.exercises[0]]);
      final next = ProgressionEngine.apply(reordered, p);
      expect(next.weeklySplit.days.first.exercises.map((e) => e.targetKg), [50, 60]);
    });

    test('summarises the biggest changes for the history list', () {
      final p = _propose(plan, s)!;
      expect(ProgressionEngine.highlights(p), ['Bench Press +2.5 kg', 'Row +2.5 kg']);
    });
  });

  group('the target weight on a saved plan', () {
    test('survives a round trip through JSON', () {
      const ex = Exercise(name: 'Bench Press', sets: 3, reps: '8-10', targetKg: 62.5);
      final back = ExerciseModel.fromJson(ExerciseModel.fromExercise(ex).toJson());
      expect(back.targetKg, 62.5);
    });

    test('is absent on plans saved before targets existed', () {
      final back = ExerciseModel.fromJson({'name': 'Squat', 'sets': 3, 'reps': '8'});
      expect(back.targetKg, isNull);
    });
  });
}
