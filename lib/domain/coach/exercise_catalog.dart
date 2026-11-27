import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/coach/session_load.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/progression/progression_engine.dart';

/// A common exercise the coach may suggest. The coach only ever suggests from
/// this list, so it cannot invent an exercise or a muscle.
class CatalogExercise {
  final String id;
  final String name;
  final MuscleGroup primary;
  final List<MuscleGroup> assists;
  final String cue;

  const CatalogExercise(this.id, this.name, this.primary, this.cue, [this.assists = const []]);

  /// Written the way plan notes are, `muscles | cue`, so the muscle map and the
  /// volume maths read it like any planned exercise.
  String get notes => '${[primary, ...assists].map((g) => g.label.toLowerCase()).join(', ')} | $cue';
}

const _g = MuscleGroup.values;

const kExerciseCatalog = <CatalogExercise>[
  CatalogExercise('incline_db_press', 'Incline Dumbbell Press', MuscleGroup.chest, 'Keep your shoulder blades back.', [MuscleGroup.shoulders, MuscleGroup.triceps]),
  CatalogExercise('cable_fly', 'Cable Fly', MuscleGroup.chest, 'Soft elbows, squeeze in the middle.'),
  CatalogExercise('push_up', 'Push-up', MuscleGroup.chest, 'Body in one straight line.', [MuscleGroup.triceps]),
  CatalogExercise('pec_deck', 'Pec Deck', MuscleGroup.chest, 'Control the way back.'),
  CatalogExercise('lat_pulldown', 'Lat Pulldown', MuscleGroup.back, 'Pull your elbows to your sides.', [MuscleGroup.biceps]),
  CatalogExercise('seated_row', 'Seated Cable Row', MuscleGroup.back, 'Lead with the elbows.', [MuscleGroup.biceps]),
  CatalogExercise('db_row', 'One-arm Dumbbell Row', MuscleGroup.back, 'Flat back, no twisting.', [MuscleGroup.biceps]),
  CatalogExercise('straight_arm_pulldown', 'Straight-arm Pulldown', MuscleGroup.back, 'Keep your arms long.'),
  CatalogExercise('lateral_raise', 'Lateral Raise', MuscleGroup.shoulders, 'Raise to shoulder height, no swinging.'),
  CatalogExercise('db_shoulder_press', 'Dumbbell Shoulder Press', MuscleGroup.shoulders, 'Brace and do not arch.', [MuscleGroup.triceps]),
  CatalogExercise('rear_delt_fly', 'Rear Delt Fly', MuscleGroup.shoulders, 'Lead with the elbows.', [MuscleGroup.back]),
  CatalogExercise('face_pull', 'Face Pull', MuscleGroup.shoulders, 'Pull toward your forehead.', [MuscleGroup.back]),
  CatalogExercise('db_curl', 'Dumbbell Curl', MuscleGroup.biceps, 'Keep your elbows still.'),
  CatalogExercise('hammer_curl', 'Hammer Curl', MuscleGroup.biceps, 'Palms face each other.', [MuscleGroup.forearms]),
  CatalogExercise('cable_curl', 'Cable Curl', MuscleGroup.biceps, 'Lower slowly.'),
  CatalogExercise('pushdown', 'Triceps Pushdown', MuscleGroup.triceps, 'Elbows stay at your sides.'),
  CatalogExercise('overhead_extension', 'Overhead Triceps Extension', MuscleGroup.triceps, 'Keep your elbows pointing up.'),
  CatalogExercise('close_grip_press', 'Close-grip Bench Press', MuscleGroup.triceps, 'Tuck your elbows.', [MuscleGroup.chest]),
  CatalogExercise('wrist_curl', 'Wrist Curl', MuscleGroup.forearms, 'Small, slow movement.'),
  CatalogExercise('farmer_walk', 'Farmer Carry', MuscleGroup.forearms, 'Stand tall and walk steadily.', [MuscleGroup.traps]),
  CatalogExercise('shrug', 'Dumbbell Shrug', MuscleGroup.traps, 'Straight up, no rolling.'),
  CatalogExercise('upright_row', 'Cable Upright Row', MuscleGroup.traps, 'Stop at chest height.', [MuscleGroup.shoulders]),
  CatalogExercise('cable_crunch', 'Cable Crunch', MuscleGroup.abs, 'Curl your ribs to your hips.'),
  CatalogExercise('hanging_knee_raise', 'Hanging Knee Raise', MuscleGroup.abs, 'No swinging.'),
  CatalogExercise('dead_bug', 'Dead Bug', MuscleGroup.abs, 'Keep your lower back down.'),
  CatalogExercise('leg_extension', 'Leg Extension', MuscleGroup.quads, 'Pause at the top.'),
  CatalogExercise('leg_press', 'Leg Press', MuscleGroup.quads, 'Do not lock your knees.', [MuscleGroup.glutes]),
  CatalogExercise('split_squat', 'Bulgarian Split Squat', MuscleGroup.quads, 'Front heel stays down.', [MuscleGroup.glutes]),
  CatalogExercise('goblet_squat', 'Goblet Squat', MuscleGroup.quads, 'Sit between your heels.', [MuscleGroup.glutes]),
  CatalogExercise('leg_curl', 'Lying Leg Curl', MuscleGroup.hamstrings, 'Control the way down.'),
  CatalogExercise('seated_leg_curl', 'Seated Leg Curl', MuscleGroup.hamstrings, 'Squeeze at the bottom.'),
  CatalogExercise('db_rdl', 'Dumbbell Romanian Deadlift', MuscleGroup.hamstrings, 'Hinge with a flat back.', [MuscleGroup.glutes]),
  CatalogExercise('hip_thrust', 'Hip Thrust', MuscleGroup.glutes, 'Finish with your hips, not your back.', [MuscleGroup.hamstrings]),
  CatalogExercise('glute_bridge', 'Glute Bridge', MuscleGroup.glutes, 'Squeeze for a second at the top.'),
  CatalogExercise('cable_kickback', 'Cable Kickback', MuscleGroup.glutes, 'Move from the hip.'),
  CatalogExercise('walking_lunge', 'Walking Lunge', MuscleGroup.glutes, 'Long steps, tall chest.', [MuscleGroup.quads]),
  CatalogExercise('standing_calf', 'Standing Calf Raise', MuscleGroup.calves, 'Full stretch, full squeeze.'),
  CatalogExercise('seated_calf', 'Seated Calf Raise', MuscleGroup.calves, 'Pause at the bottom.'),
];

/// One suggested exercise, with the numbers already filled in.
class Suggestion {
  final CatalogExercise exercise;
  final int sets;
  final String reps;

  /// The last weight logged for this exercise, when there is one.
  final double? weightKg;

  /// Why it was picked, in plain words, from the numbers.
  final String why;

  const Suggestion({
    required this.exercise,
    required this.sets,
    required this.reps,
    this.weightKg,
    required this.why,
  });

  Suggestion copyWith({int? sets, String? why}) => Suggestion(
        exercise: exercise,
        sets: sets ?? this.sets,
        reps: reps,
        weightKg: weightKg,
        why: why ?? this.why,
      );

  Exercise toExercise() => Exercise(
        name: exercise.name,
        sets: sets,
        reps: reps,
        notes: exercise.notes,
        targetKg: weightKg,
      );
}

/// Picks what could fit the session, by rules. The model may choose among these
/// and explain them; it cannot add to them.
class ExerciseSuggester {
  ExerciseSuggester._();

  static const maxExtraSets = 12;

  static const _accessory = {
    MuscleGroup.forearms, MuscleGroup.traps, MuscleGroup.abs, MuscleGroup.calves,
  };
  static const _upper = {
    MuscleGroup.chest, MuscleGroup.back, MuscleGroup.shoulders, MuscleGroup.biceps,
    MuscleGroup.triceps, MuscleGroup.forearms, MuscleGroup.traps, MuscleGroup.abs,
  };
  static const _lower = {
    MuscleGroup.quads, MuscleGroup.hamstrings, MuscleGroup.glutes, MuscleGroup.calves, MuscleGroup.abs,
  };
  static const _push = {MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.triceps, MuscleGroup.abs};
  static const _pull = {
    MuscleGroup.back, MuscleGroup.biceps, MuscleGroup.traps, MuscleGroup.forearms, MuscleGroup.abs,
  };

  /// The muscle groups that belong in today's session, read from what it
  /// trains. A push day stays a push day; a mixed day allows everything.
  static Set<MuscleGroup> groupsFor(SessionLoad load) {
    final main = {for (final v in load.trainedToday) if (v.today >= 2) v.group}..remove(MuscleGroup.abs);
    if (main.isEmpty) return _g.toSet();
    for (final kind in [_push, _pull, _upper, _lower]) {
      if (main.every(kind.contains)) return kind;
    }
    return _g.toSet();
  }

  /// Reps for an added exercise: moderate ranges that suit accessory work.
  static String repsFor(GoalKind goal, {bool beginner = false}) => switch (goal) {
        GoalKind.strength => beginner ? '8-12' : '5-6',
        GoalKind.hypertrophy => '8-12',
        GoalKind.fatLoss => '12-15',
        GoalKind.general => '8-12',
      };

  /// Up to [limit] suggestions, the muscles furthest behind first, never one
  /// already in [today].
  static List<Suggestion> candidates({
    required List<Exercise> today,
    required SessionLoad load,
    required GoalKind goal,
    bool beginner = false,
    ExerciseHistory Function(String name)? historyOf,
    int limit = 10,
  }) {
    final taken = {for (final e in today) ExerciseHistory.keyFor(e.name)};
    final allowed = groupsFor(load);
    final sore = load.soreness == Soreness.aBitSore;
    final verySore = load.soreness == Soreness.verySore;

    var groups = [
      for (final g in allowed)
        if (!sore || (load.volumes[g]!.today == 0)) g
    ];
    // A bit sore on a day that already trains everything in its split: look
    // wider for muscles that have rested.
    if (sore && groups.isEmpty) {
      groups = [for (final g in _g) if (load.volumes[g]!.today == 0) g];
    }

    double behind(MuscleGroup g) {
      final v = load.volumes[g]!;
      return v.target == 0 ? 0 : v.deficit / v.target;
    }

    // Main muscles first. Otherwise the small ones, which nothing trains
    // directly and so are always furthest behind, would lead every list.
    int rank(MuscleGroup g) => _accessory.contains(g) ? 1 : 0;
    groups.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      final d = behind(b).compareTo(behind(a));
      return d != 0 ? d : a.index.compareTo(b.index);
    });

    final byGroup = [
      for (final g in groups)
        [
          for (final c in kExerciseCatalog)
            if (c.primary == g && !taken.contains(ExerciseHistory.keyFor(c.name))) c
        ]
    ];

    final out = <Suggestion>[];
    // One per group first, then a second round, so the list stays varied.
    for (var round = 0; round < 2 && out.length < limit; round++) {
      for (var i = 0; i < groups.length && out.length < limit; i++) {
        if (round >= byGroup[i].length) continue;
        final c = byGroup[i][round];
        final v = load.volumes[c.primary]!;
        final sets = verySore || sore ? 2 : 3;
        out.add(Suggestion(
          exercise: c,
          sets: sets,
          reps: repsFor(goal, beginner: beginner),
          weightKg: historyOf?.call(c.name).last?.bestSet?.weightKg,
          why: v.deficit > 0
              ? '${c.primary.label}: ${formatSets(v.week)} of about ${formatSets(v.target)} sets this week.'
              : '${c.primary.label} is already at its weekly target.',
        ));
      }
    }
    return out;
  }

  /// A short extra workout from [candidates]: up to four exercises for
  /// different muscles, within the sets that still fit (at least enough for two
  /// exercises, since the user may choose to train past the advice).
  static List<Suggestion> workout(List<Suggestion> candidates, {required int roomSets}) {
    final budget = roomSets.clamp(6, maxExtraSets);
    final out = <Suggestion>[];
    final used = <MuscleGroup>{};
    var sets = 0;
    for (final s in candidates) {
      if (out.length == 4) break;
      if (!used.add(s.exercise.primary)) continue;
      final remaining = budget - sets;
      if (remaining < 2) break;
      final take = s.sets > remaining ? remaining : s.sets;
      out.add(s.copyWith(sets: take));
      sets += take;
    }
    return out;
  }
}
