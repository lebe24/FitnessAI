import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/models/muscle.dart';
import 'package:fitness/domain/models/muscle_coverage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every string below is copied from the production export
/// (workout_sessions_rows.csv). The muscles live in free text on the
/// prescription half of each entry, and the muscle_group column is null on
/// every row ever written, so this parsing is the only source there is.
WorkoutSessionModel _session(List<Map<String, dynamic>> logs) =>
    WorkoutSessionModel.fromJson({
      'session_date': '2026-08-25',
      'is_completed': true,
      'workout_logs': logs,
    });

Map<String, dynamic> _entry(String name, String notes) =>
    {'name': name, 'notes': notes};

void main() {
  group('reading muscles out of the notes', () {
    test('a comma list resolves in order', () {
      expect(MuscleCoverage.musclesIn('shoulders, upper back'),
          ['deltoids', 'upper-back']);
      expect(MuscleCoverage.musclesIn('hamstrings, glutes'),
          ['hamstring', 'gluteal']);
    });

    test('"lower back" is not read as "back"', () {
      expect(MuscleCoverage.musclesIn('hamstrings, lower back'),
          ['hamstring', 'lower-back']);
      expect(MuscleCoverage.musclesIn('back, biceps'), ['upper-back', 'biceps']);
    });

    test('muscles are found inside a coaching sentence', () {
      // Not every prescription note is a tidy list.
      expect(
        MuscleCoverage.musclesIn(
            'Supports posterior chain development by focusing on the lower back.'),
        ['lower-back'],
      );
    });

    test('synonyms collapse onto one muscle, counted once', () {
      expect(MuscleCoverage.musclesIn('abs, core'), ['abs']);
      expect(MuscleCoverage.musclesIn('pecs and chest'), ['chest']);
    });

    test('text naming nothing drawable resolves to nothing', () {
      expect(MuscleCoverage.musclesIn('Focus on control and full range'),
          isEmpty);
      expect(MuscleCoverage.musclesIn(''), isEmpty);
    });

    test('every resolved slug is a muscle the map can draw', () {
      const samples = [
        'shoulders, upper back', 'forearms, biceps', 'back, abs',
        'hamstrings, glutes', 'obliques', 'quads, glutes', 'calves', 'shins',
      ];
      final drawable = Muscle.all.map((m) => m.slug).toSet();
      for (final s in samples) {
        for (final slug in MuscleCoverage.musclesIn(s)) {
          expect(drawable, contains(slug), reason: '$s -> $slug');
        }
      }
    });
  });

  group('falling back when the plan says nothing', () {
    // Nearly half the exercises in a real export have no prescription entry at
    // all, so notes alone leaves the map looking broken.
    test('the exercise name is read when there are no notes', () {
      expect(MuscleCoverage.musclesFor(name: 'Standing Calf Raises'), ['calves']);
      expect(MuscleCoverage.musclesFor(name: 'Triceps Pull Down'), ['triceps']);
      expect(MuscleCoverage.musclesFor(name: 'lat pulldown'), ['upper-back']);
      expect(MuscleCoverage.musclesFor(name: 'hip adductors'), ['adductors']);
    });

    test('notes beat the name when both are present', () {
      // "Lat pulldown" would read as upper back alone; the plan knows better.
      expect(
        MuscleCoverage.musclesFor(
            name: 'lat pulldown', notes: 'back, biceps | Lead with your chest'),
        ['upper-back', 'biceps'],
      );
    });

    test('classic lifts that name no muscle still resolve', () {
      expect(MuscleCoverage.musclesFor(name: 'Barbell Bench Press').first, 'chest');
      expect(MuscleCoverage.musclesFor(name: 'Leg Press').first, 'quadriceps');
      expect(MuscleCoverage.musclesFor(name: 'Pull-ups').first, 'upper-back');
      expect(MuscleCoverage.musclesFor(name: 'Dumbbell Shrug'), ['trapezius']);
      expect(MuscleCoverage.musclesFor(name: 'Deadlift').first, 'hamstring');
    });

    test('an exercise nobody can place resolves to nothing', () {
      expect(MuscleCoverage.musclesFor(name: 'Mystery Move'), isEmpty);
    });
  });

  group('coverage from sessions', () {
    test('sets count towards the muscles the prescription names', () {
      final c = MuscleCoverage.fromSessions([
        _session([
          _entry('lat pulldown', 'back, biceps | Lead with your chest'),
          _entry('lat pulldown', 'set 1: 10 reps @ 113kg | set 2: 10 reps @ 107kg'),
        ]),
      ]);

      // Two sets performed; the first-named muscle takes them in full and the
      // assisting one counts half.
      expect(c.load['upper-back'], 2.0);
      expect(c.load['biceps'], 1.0);
      expect(c.resolvedExercises, 1);
      expect(c.unresolvedExercises, 0);
    });

    test('an exercise with no muscle text is reported, not dropped', () {
      final c = MuscleCoverage.fromSessions([
        _session([
          _entry('mystery move', 'Focus on control'),
          _entry('mystery move', 'set 1: 8 reps @ 40kg'),
        ]),
      ]);
      expect(c.isEmpty, isTrue);
      expect(c.unresolvedExercises, 1,
          reason: 'a map that hides a third of the training is worse than one '
              'that admits it');
    });

    test('skipped sets do not count as training', () {
      final c = MuscleCoverage.fromSessions([
        _session([
          _entry('squat', 'quads, glutes'),
          _entry('squat', 'set 1: 0 reps @ 0kg | set 2: 0 reps @ 0kg'),
        ]),
      ]);
      expect(c.isEmpty, isTrue);
    });

    test('load accumulates across sessions', () {
      final s = _session([
        _entry('curl', 'biceps'),
        _entry('curl', 'set 1: 10 reps @ 20kg | set 2: 10 reps @ 20kg'),
      ]);
      final c = MuscleCoverage.fromSessions([s, s, s]);
      expect(c.load['biceps'], 6.0);
    });
  });

  group('shading', () {
    test('the hardest-worked muscle is the top bucket, untrained is zero', () {
      const c = MuscleCoverage(
        load: {'chest': 8, 'biceps': 2, 'abs': 1},
        unresolvedExercises: 0,
        resolvedExercises: 3,
      );
      final l = c.levels;
      expect(l['chest'], 4);
      expect(l['biceps'], inInclusiveRange(1, 3));
      expect(l['abs'], inInclusiveRange(1, 3));
      expect(l['calves'], 0, reason: 'never trained');
      expect(l['biceps']!, greaterThanOrEqualTo(l['abs']!));
    });

    test('a muscle with any training is never shaded as untrained', () {
      const c = MuscleCoverage(
        load: {'chest': 100, 'tibialis': 0.5},
        unresolvedExercises: 0,
        resolvedExercises: 2,
      );
      expect(c.levels['tibialis'], 1);
    });

    test('ranked lists the heaviest first', () {
      const c = MuscleCoverage(
        load: {'abs': 2, 'chest': 9, 'biceps': 5},
        unresolvedExercises: 0,
        resolvedExercises: 3,
      );
      expect(c.ranked, ['chest', 'biceps', 'abs']);
    });

    test('no sessions is empty rather than a blank body', () {
      final c = MuscleCoverage.fromSessions([]);
      expect(c.isEmpty, isTrue);
      expect(c.levels.values.every((v) => v == 0), isTrue);
    });
  });
}
