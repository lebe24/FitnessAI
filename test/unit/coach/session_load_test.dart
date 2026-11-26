import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/coach/session_load.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import 'coach_fixtures.dart';

Exercise _ex(String name, int n, [String? notes]) => Exercise(name: name, sets: n, reps: '10', notes: notes);

SessionLoad _load(
  List<Exercise> today, {
  List<WorkoutSessionModel> sessions = const [],
  GoalType? goal = GoalType.buildMuscle,
  Soreness? soreness,
}) =>
    SessionLoad.analyse(today: today, sessions: sessions, now: coachNow, goal: goal, soreness: soreness);

void main() {
  test('the first muscle counts a full set and assistants half', () {
    final l = _load([_ex('Press', 4, 'chest, triceps, shoulders | cue')]);
    expect(l.volumes[MuscleGroup.chest]!.today, 4);
    expect(l.volumes[MuscleGroup.triceps]!.today, 2);
    expect(l.volumes[MuscleGroup.shoulders]!.today, 2);
    expect(l.totalSets, 4);
  });

  test('a short session has room for more', () {
    final l = _load([_ex('Bench Press', 4, 'chest | x')]);
    expect(l.verdict, VolumeVerdict.room);
    expect(l.headline, 'Room for a bit more');
    expect(l.roomSets, greaterThan(0));
    expect(l.advice, contains('Chest'));
  });

  test('more than ten sets for one muscle is enough', () {
    final l = _load([_ex('Bench Press', 6, 'chest | x'), _ex('Cable Fly', 5, 'chest | x')]);
    expect(l.verdict, VolumeVerdict.enough);
    expect(l.advice, contains('11 sets today'));
    expect(l.roomSets, 0);
  });

  test('a very long session is enough', () {
    final l = _load([
      _ex('Bench Press', 9, 'chest | x'),
      _ex('Lat Pulldown', 9, 'back | x'),
      _ex('Leg Extension', 8, 'quads | x'),
    ]);
    expect(l.totalSets, 26);
    expect(l.verdict, VolumeVerdict.enough);
    expect(l.advice, contains('26 sets'));
  });

  test('every trained muscle at its weekly target is enough', () {
    final l = _load(
      [_ex('Bench Press', 4, 'chest | x')],
      sessions: [logged(3, {'Bench Press': sets(9, 10, 60)})],
    );
    expect(l.volumes[MuscleGroup.chest]!.week, 13);
    expect(l.verdict, VolumeVerdict.enough);
    expect(l.advice, contains('weekly target'));
  });

  test('far past the weekly target is a stop', () {
    final l = _load(
      [_ex('Bench Press', 8, 'chest | x')],
      sessions: [logged(2, {'Bench Press': sets(8, 10, 60)}), logged(5, {'Cable Fly': sets(6, 12, 15)})],
    );
    expect(l.verdict, VolumeVerdict.stop);
    expect(l.headline, 'Chest has had plenty this week');
    expect(l.advice, contains(SessionLoad.painNote));
  });

  test('very sore is a stop however little was done', () {
    final l = _load([_ex('Bench Press', 2, 'chest | x')], soreness: Soreness.verySore);
    expect(l.verdict, VolumeVerdict.stop);
    expect(l.headline, 'Call it here');
    expect(l.roomSets, 0);
  });

  test('a bit sore keeps the verdict but advises going light', () {
    final fresh = _load([_ex('Bench Press', 3, 'chest | x')]);
    final sore = _load([_ex('Bench Press', 3, 'chest | x')], soreness: Soreness.aBitSore);
    expect(sore.verdict, VolumeVerdict.room);
    expect(sore.advice, contains('a bit sore'));
    expect(sore.roomSets, lessThanOrEqualTo(6));
    expect(sore.roomSets, lessThanOrEqualTo(fresh.roomSets));
  });

  test('rows already logged today are not counted a second time', () {
    final l = _load(
      [_ex('Bench Press', 4, 'chest | x')],
      sessions: [logged(0, {'Bench Press': sets(4, 10, 60)})],
    );
    expect(l.volumes[MuscleGroup.chest]!.week, 4);
  });

  test('a set list saved twice on one day counts once', () {
    final twice = WorkoutSessionModel(
      sessionDate: DateTime(2026, 11, 24),
      workoutLogs: [
        for (var i = 0; i < 2; i++)
          {'name': 'Bench Press', 'notes': 'set 1: 10 reps @ 60kg | set 2: 10 reps @ 60kg'},
      ],
    );
    final l = _load([_ex('Bench Press', 1, 'chest | x')], sessions: [twice]);
    expect(l.volumes[MuscleGroup.chest]!.earlier, 2);
  });

  test('work older than six days is not this week', () {
    final l = _load(
      [_ex('Bench Press', 1, 'chest | x')],
      sessions: [logged(7, {'Bench Press': sets(8, 10, 60)})],
    );
    expect(l.volumes[MuscleGroup.chest]!.earlier, 0);
  });

  test('the weekly target follows the goal', () {
    expect(_load([_ex('Bench Press', 1)], goal: GoalType.maintain).volumes[MuscleGroup.chest]!.target, 6);
    expect(_load([_ex('Bench Press', 1)], goal: GoalType.buildMuscle).volumes[MuscleGroup.chest]!.target, 12);
  });

  test('an empty session has room', () {
    expect(_load([]).verdict, VolumeVerdict.room);
  });

  test('set counts print without a needless decimal', () {
    expect(formatSets(7), '7');
    expect(formatSets(4.5), '4.5');
  });
}
