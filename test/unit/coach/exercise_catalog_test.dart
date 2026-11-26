import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/coach/exercise_catalog.dart';
import 'package:fitness/domain/coach/session_load.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/muscle_coverage.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/progression/progression_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'coach_fixtures.dart';

Exercise _ex(String name, int n, String muscles) => Exercise(name: name, sets: n, reps: '10', notes: '$muscles | x');

SessionLoad _load(List<Exercise> today, {Soreness? soreness}) =>
    SessionLoad.analyse(today: today, sessions: const [], now: coachNow, soreness: soreness);

List<Suggestion> _candidates(List<Exercise> today, {Soreness? soreness}) => ExerciseSuggester.candidates(
      today: today,
      load: _load(today, soreness: soreness),
      goal: GoalKind.hypertrophy,
    );

const _upper = {
  MuscleGroup.chest, MuscleGroup.back, MuscleGroup.shoulders, MuscleGroup.biceps,
  MuscleGroup.triceps, MuscleGroup.forearms, MuscleGroup.traps, MuscleGroup.abs,
};

void main() {
  test('ids are unique', () {
    expect({for (final c in kExerciseCatalog) c.id}.length, kExerciseCatalog.length);
  });

  test('every muscle group has at least two exercises', () {
    for (final g in MuscleGroup.values) {
      expect(kExerciseCatalog.where((c) => c.primary == g).length, greaterThanOrEqualTo(2), reason: g.name);
    }
  });

  test('the muscle matcher reads each entry as its own main muscle', () {
    for (final c in kExerciseCatalog) {
      final slugs = MuscleCoverage.musclesFor(name: c.name, notes: c.notes);
      expect(slugs, isNotEmpty, reason: c.name);
      expect(MuscleGroup.forSlug(slugs.first), c.primary, reason: '${c.name}: ${c.notes} -> $slugs');
    }
  });

  test('never suggests an exercise already in the session', () {
    final today = [_ex('Lateral Raise', 3, 'shoulders'), _ex('Cable Fly', 3, 'chest')];
    final keys = {for (final s in _candidates(today)) ExerciseHistory.keyFor(s.exercise.name)};
    expect(keys, isNot(contains(ExerciseHistory.keyFor('Lateral Raise'))));
    expect(keys, isNot(contains(ExerciseHistory.keyFor('Cable Fly'))));
  });

  test('a push day only suggests push muscles and abs', () {
    final today = [_ex('Bench Press', 4, 'chest, triceps'), _ex('Shoulder Press', 3, 'shoulders')];
    final groups = {for (final s in _candidates(today)) s.exercise.primary};
    expect(
      groups.difference({MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.triceps, MuscleGroup.abs}),
      isEmpty,
    );
  });

  test('an upper day never suggests legs', () {
    final today = [_ex('Bench Press', 4, 'chest'), _ex('Lat Pulldown', 4, 'back')];
    expect({for (final s in _candidates(today)) s.exercise.primary}.difference(_upper), isEmpty);
  });

  test('main muscles are suggested before small accessory ones', () {
    final list = _candidates([_ex('Bench Press', 4, 'chest'), _ex('Lat Pulldown', 3, 'back')]);
    const accessory = {MuscleGroup.forearms, MuscleGroup.traps, MuscleGroup.abs, MuscleGroup.calves};
    expect(list.take(3).any((s) => accessory.contains(s.exercise.primary)), isFalse);
    final firstSmall = list.indexWhere((s) => accessory.contains(s.exercise.primary));
    if (firstSmall >= 0) expect(firstSmall, greaterThanOrEqualTo(5));
  });

  test('among main muscles the furthest behind leads', () {
    final first = _candidates([_ex('Bench Press', 8, 'chest')]).first;
    expect(first.exercise.primary, isNot(MuscleGroup.chest));
  });

  test('a lower day suggests lower body', () {
    final today = [_ex('Squat', 4, 'quads, glutes')];
    expect({for (final s in _candidates(today)) s.exercise.primary}.intersection({MuscleGroup.chest, MuscleGroup.back}), isEmpty);
  });

  test('a bit sore skips muscles trained today and drops a set', () {
    final today = [_ex('Bench Press', 4, 'chest, triceps')];
    final list = _candidates(today, soreness: Soreness.aBitSore);
    expect(list, isNotEmpty);
    expect(list.any((s) => s.exercise.primary == MuscleGroup.chest), isFalse);
    expect(list.every((s) => s.sets == 2), isTrue);
  });

  test('suggestions say why, using the numbers', () {
    final s = _candidates([_ex('Bench Press', 4, 'chest')]).first;
    expect(s.why, contains('sets this week'));
  });

  test('an added exercise carries its muscles in the notes', () {
    final e = _candidates([_ex('Bench Press', 4, 'chest')]).first.toExercise();
    expect(e.notes, contains('|'));
    expect(MuscleCoverage.musclesFor(name: e.name, notes: e.notes!), isNotEmpty);
  });

  test('the last logged weight comes along', () {
    final list = ExerciseSuggester.candidates(
      today: [_ex('Bench Press', 4, 'chest')],
      load: _load([_ex('Bench Press', 4, 'chest')]),
      goal: GoalKind.hypertrophy,
      historyOf: (name) => ExerciseHistory.fromSessions([logged(3, {name: sets(3, 10, 22)})], name),
    );
    expect(list.first.weightKg, 22);
  });

  group('extra workout', () {
    test('up to four exercises for different muscles', () {
      final w = ExerciseSuggester.workout(_candidates([_ex('Bench Press', 3, 'chest'), _ex('Row', 3, 'back')]), roomSets: 12);
      expect(w.length, inInclusiveRange(3, 4));
      expect({for (final s in w) s.exercise.primary}.length, w.length);
      expect(w.fold<int>(0, (t, s) => t + s.sets), lessThanOrEqualTo(12));
    });

    test('is still small when there is no room, for someone training past the advice', () {
      final w = ExerciseSuggester.workout(_candidates([_ex('Bench Press', 12, 'chest')]), roomSets: 0);
      expect(w, isNotEmpty);
      expect(w.fold<int>(0, (t, s) => t + s.sets), lessThanOrEqualTo(6));
    });
  });
}
