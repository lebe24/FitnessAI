import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/models/session_share.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSessionModel _session(int day, List<(String, String)> exercises, {String? label = 'Tuesday', int mins = 60}) =>
    WorkoutSessionModel(
      sessionDate: DateTime(2026, 11, day),
      dayLabel: label,
      durationMins: mins,
      workoutLogs: [
        for (final (name, sets) in exercises) {'name': name, 'notes': sets}
      ],
    );

final _today = _session(24, [
  ('Barbell Squat', 'set 1: 20 reps @ 50kg | set 2: 7 reps @ 100kg | set 3: 5 reps @ 100kg'),
  ('Barbell Squat', 'set 1: 20 reps @ 50kg | set 2: 7 reps @ 100kg | set 3: 0 reps @ 100kg'),
  ('Standing Calf Raises', 'set 1: 15 reps @ 150kg | set 2: 18 reps @ 150kg'),
  ('Hanging Leg Raises', 'set 1: 8 reps @ 0kg | set 2: 10 reps @ 0kg'),
]);

void main() {
  test('totals match what the history screen shows', () {
    final s = SessionShare.of(_today);
    expect(s.title, 'Tuesday');
    expect(s.durationMins, 60);
    expect(s.exercises, 4);
    expect(s.sets, 9);
    expect(s.volumeKg, 1000 + 700 + 500 + 1000 + 700 + 2250 + 2700);
    expect(s.reps, 20 + 7 + 5 + 20 + 7 + 15 + 18 + 8 + 10);
  });

  test('an exercise saved twice is listed once, with its best set', () {
    final lifts = SessionShare.of(_today).lifts;
    expect(lifts.where((l) => l.name == 'Barbell Squat'), hasLength(1));
    final squat = lifts.firstWhere((l) => l.name == 'Barbell Squat');
    expect(squat.weightKg, 100);
    expect(squat.reps, 7); // the most reps at the top weight
  });

  test('bodyweight work has reps and no weight', () {
    final raise = SessionShare.of(_today).lifts.firstWhere((l) => l.name == 'Hanging Leg Raises');
    expect(raise.weightKg, isNull);
    expect(raise.reps, 10);
  });

  test('a heavier top set than any earlier day is a new best, and leads', () {
    final s = SessionShare.of(_today, history: [
      _session(17, [('Barbell Squat', 'set 1: 5 reps @ 95kg')]),
      _session(10, [('Standing Calf Raise', 'set 1: 10 reps @ 150kg')]),
      _today,
    ]);
    expect(s.bests, 1);
    expect(s.lifts.first.name, 'Barbell Squat');
    expect(s.lifts.first.isBest, isTrue);
  });

  test('equalling a weight, a first visit, and later sessions are not records', () {
    final s = SessionShare.of(_today, history: [
      _session(17, [('Barbell Squat', 'set 1: 5 reps @ 100kg')]),
      _session(30, [('Standing Calf Raises', 'set 1: 5 reps @ 60kg')]), // after today
    ]);
    expect(s.bests, 0);
  });

  test('other rows from the same day do not count as earlier', () {
    final s = SessionShare.of(_today, history: [
      _session(24, [('Barbell Squat', 'set 1: 5 reps @ 60kg')]),
    ]);
    expect(s.bests, 0);
  });

  test('otherwise the biggest load leads', () {
    expect(SessionShare.of(_today).lifts.first.name, 'Standing Calf Raises');
  });

  test('says which muscles were trained', () {
    final s = SessionShare.of(_today);
    expect(s.muscles, isNotEmpty);
    expect(s.muscleLevels.values.every((v) => v >= 1 && v <= 4), isTrue);
  });

  test('a session with no name is a Workout', () {
    expect(SessionShare.of(_session(24, [], label: '  ')).title, 'Workout');
  });

  test('a session with no sets is empty', () {
    expect(SessionShare.of(_session(24, [])).isEmpty, isTrue);
  });
}
