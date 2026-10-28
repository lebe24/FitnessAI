import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/models/muscle.dart';
import 'package:fitness/domain/models/session_volume.dart';

/// Which muscles the logged sessions actually trained, and how much.
///
/// The data is awkward. `workout_sessions.workout_logs` interleaves the
/// prescription and the record: the same exercise appears twice, once with
/// coaching text and once with set data. The muscles are named only in the
/// prescription half, as free text — "shoulders, upper back" — and the
/// `muscle_group` column is null on every row ever written. So the muscles are
/// recovered by reading that text, and exercises whose text names nothing
/// recognisable are counted as unresolved rather than guessed at.
///
/// Written for this data, not ported: Iron Index resolves muscles from a
/// dataset field that BeFit does not have, and its table came from an AGPL
/// project. See NOTICE.md.
class MuscleCoverage {
  /// Sets performed per muscle slug, first-named muscle weighted highest.
  final Map<String, double> load;

  /// Exercises whose notes named no muscle we can draw. Reported, not hidden:
  /// a body map that silently ignores a third of the training is worse than
  /// one that says so.
  final int unresolvedExercises;

  /// Exercises that did resolve, for the "out of" in that sentence.
  final int resolvedExercises;

  /// Sets per exercise, per muscle: which movements built each muscle's total.
  /// The body map answers "where"; this answers "from what".
  final Map<String, Map<String, double>> byExercise;

  const MuscleCoverage({
    required this.load,
    required this.unresolvedExercises,
    required this.resolvedExercises,
    this.byExercise = const {},
  });

  static const empty = MuscleCoverage(
    load: {},
    unresolvedExercises: 0,
    resolvedExercises: 0,
  );

  /// Every weighted set that landed on a muscle the map can draw.
  double get totalLoad => load.values.fold(0, (sum, v) => sum + v);

  /// This muscle's share of that total, 0-100. Zero when nothing is logged,
  /// rather than a division by zero.
  double sharePercent(String slug) {
    final total = totalLoad;
    if (total <= 0) return 0;
    return ((load[slug] ?? 0) / total) * 100;
  }

  /// Exercises that trained [slug], heaviest first.
  List<MapEntry<String, double>> exercisesFor(String slug) {
    final entries = (byExercise[slug] ?? const {}).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  bool get isEmpty => load.isEmpty;

  /// Muscles present, heaviest first.
  List<String> get ranked {
    final slugs = load.keys.toList()
      ..sort((a, b) => load[b]!.compareTo(load[a]!));
    return slugs;
  }

  /// Shade buckets 1–4 per muscle, relative to the hardest-worked muscle in
  /// the same set of sessions. Relative on purpose: the map answers "where is
  /// my training concentrated", which only means anything as a comparison
  /// within one period. 0 means untrained.
  Map<String, int> get levels {
    final max = load.values.fold<double>(0, (m, v) => v > m ? v : m);
    final out = <String, int>{};
    for (final m in Muscle.all) {
      final v = load[m.slug] ?? 0;
      out[m.slug] = v <= 0 || max <= 0
          ? 0
          : (((v / max) * 4).ceil()).clamp(1, 4);
    }
    return out;
  }

  /// Build from logged sessions.
  ///
  /// Weighting is by sets performed, not volume: volume is dominated by a few
  /// heavy compound lifts, which would paint the legs bright and the shoulders
  /// dark on a session that trained both equally hard.
  factory MuscleCoverage.fromSessions(List<WorkoutSessionModel> sessions) {
    final load = <String, double>{};
    final byExercise = <String, Map<String, double>>{};
    var resolved = 0;
    var unresolved = 0;

    for (final session in sessions) {
      final described = _muscleTextByExercise(session);

      for (final exercise in SessionVolume.exercisesOf(session)) {
        final sets = exercise.performedSets;
        if (sets == 0) continue;

        final muscles = musclesFor(
          name: exercise.name,
          notes: '${described[exercise.name.toLowerCase().trim()] ?? ''} '
              '${exercise.muscleGroup ?? ''}',
        );
        if (muscles.isEmpty) {
          unresolved++;
          continue;
        }
        resolved++;

        // The first muscle named is the one being trained; the rest assist.
        for (var i = 0; i < muscles.length; i++) {
          final slug = muscles[i];
          final weight = i == 0 ? sets.toDouble() : sets * 0.5;
          load[slug] = (load[slug] ?? 0) + weight;
          final perExercise = byExercise.putIfAbsent(slug, () => {});
          perExercise[exercise.name] = (perExercise[exercise.name] ?? 0) + weight;
        }
      }
    }

    return MuscleCoverage(
      load: load,
      unresolvedExercises: unresolved,
      resolvedExercises: resolved,
      byExercise: byExercise,
    );
  }

  /// The coaching text for each exercise in a session, keyed by exercise name.
  ///
  /// Entries carrying set data are the record; the others are the plan, and
  /// only the plan names muscles.
  static Map<String, String> _muscleTextByExercise(
      WorkoutSessionModel session) {
    final out = <String, String>{};
    for (final entry in session.workoutLogs) {
      final notes = entry['notes'];
      if (notes is! String || notes.isEmpty) continue;
      if (SessionVolume.parseSets(notes).isNotEmpty) continue;
      final name = (entry['name'] as String?)?.toLowerCase().trim();
      if (name == null || name.isEmpty) continue;
      // Only the muscle list, never the cue that follows it.
      out[name] = '${out[name] ?? ''} ${notes.split('|').first.trim()}';
    }
    return out;
  }

  /// Every muscle an exercise trains, best source first.
  ///
  /// The plan's coaching text is the only real data, so it wins. Failing that
  /// the name often says it outright — "standing calf raises", "triceps pull
  /// down" — and failing *that* a short table covers the classic lifts whose
  /// names mention no muscle at all. Without the last two, roughly half of a
  /// real export resolves to nothing and the map looks broken rather than
  /// honest.
  static List<String> musclesFor({required String name, String notes = ''}) {
    // A plan note reads "<muscles> | <coaching cue>", and only the head names
    // what is being trained. The cue routinely mentions parts it does not
    // train — "back, biceps | Lead with your chest" is a back exercise, and
    // reading the whole string puts chest on the map.
    final fromNotes = musclesIn(notes.split('|').first);
    if (fromNotes.isNotEmpty) return fromNotes;

    final fromName = musclesIn(name);
    if (fromName.isNotEmpty) return fromName;

    final lower = name.toLowerCase();
    for (final lift in _commonLifts.entries) {
      if (lower.contains(lift.key)) return lift.value;
    }
    return const [];
  }

  /// Lifts whose names name no muscle, kept deliberately short and explicit
  /// so it can be read and argued with. First slug is the muscle trained, the
  /// rest assist — the same convention the coaching text follows.
  static const Map<String, List<String>> _commonLifts = {
    'bench press': ['chest', 'triceps', 'deltoids'],
    'push up': ['chest', 'triceps'],
    'push-up': ['chest', 'triceps'],
    'pull up': ['upper-back', 'biceps'],
    'pull-up': ['upper-back', 'biceps'],
    'chin up': ['upper-back', 'biceps'],
    'face pull': ['deltoids', 'upper-back'],
    'leg press': ['quadriceps', 'gluteal'],
    'leg extension': ['quadriceps'],
    'leg curl': ['hamstring'],
    'lunge': ['quadriceps', 'gluteal'],
    'squat': ['quadriceps', 'gluteal'],
    'deadlift': ['hamstring', 'lower-back', 'gluteal'],
    'shrug': ['trapezius'],
    'plank': ['abs'],
    'russian twist': ['obliques'],
    'dip': ['triceps', 'chest'],
  };

  /// Muscles named in a piece of free text, in the order they appear.
  ///
  /// Longest phrases are matched first so "lower back" is not read as "back",
  /// and each muscle is reported once however many times it is mentioned.
  static List<String> musclesIn(String text) {
    var remaining = text.toLowerCase();
    final found = <String, int>{};

    // Longest phrase first, and every match is blanked out before the shorter
    // patterns run. Without that, "lower back" also matches the bare "back"
    // and the text resolves to both the lower and the upper back.
    final patterns = _vocabulary.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final pattern in patterns) {
      final re = RegExp('\\b$pattern\\b');
      final match = re.firstMatch(remaining);
      if (match == null) continue;

      final slug = _vocabulary[pattern]!;
      final at = match.start;
      if (!found.containsKey(slug) || at < found[slug]!) found[slug] = at;

      // Spaces, not removal, so the offsets of later matches stay honest.
      remaining = remaining.replaceAllMapped(
          re, (m) => ' ' * m.group(0)!.length);
    }

    final slugs = found.keys.toList()
      ..sort((a, b) => found[a]!.compareTo(found[b]!));
    return slugs;
  }

  /// Every muscle word seen in the exported sessions, plus the obvious
  /// synonyms. Order here does not matter — [musclesIn] sorts by length.
  static final Map<String, String> _vocabulary = Map.fromEntries([
    // Two-word phrases must be tried before their single-word parts.
    MapEntry('lower back', 'lower-back'),
    MapEntry('upper back', 'upper-back'),
    MapEntry('latissimus dorsi', 'upper-back'),
    MapEntry('hip flexors?', 'hip-flexors'),
    MapEntry('inner thighs?', 'adductors'),
    MapEntry('rotator cuff', 'deltoids'),
    MapEntry('rear delts?', 'deltoids'),
    MapEntry('upper chest', 'chest'),
    MapEntry('tibialis anterior', 'tibialis'),
    // Single words.
    MapEntry('traps?', 'trapezius'),
    MapEntry('trapezius', 'trapezius'),
    MapEntry('shoulders?', 'deltoids'),
    MapEntry('delts?', 'deltoids'),
    MapEntry('deltoids?', 'deltoids'),
    MapEntry('chest', 'chest'),
    MapEntry('pecs?', 'chest'),
    MapEntry('pectorals?', 'chest'),
    MapEntry('lats?', 'upper-back'),
    MapEntry('rhomboids?', 'upper-back'),
    MapEntry('back', 'upper-back'),
    MapEntry('serratus', 'serratus'),
    MapEntry('biceps?', 'biceps'),
    MapEntry('brachialis', 'biceps'),
    MapEntry('triceps?', 'triceps'),
    MapEntry('forearms?', 'forearm'),
    MapEntry('grip', 'forearm'),
    MapEntry('wrists?', 'forearm'),
    MapEntry('abs', 'abs'),
    MapEntry('abdominals?', 'abs'),
    MapEntry('core', 'abs'),
    MapEntry('obliques?', 'obliques'),
    MapEntry('spine', 'lower-back'),
    MapEntry('erectors?', 'lower-back'),
    MapEntry('glutes?', 'gluteal'),
    MapEntry('gluteals?', 'gluteal'),
    MapEntry('quads?', 'quadriceps'),
    MapEntry('quadriceps', 'quadriceps'),
    MapEntry('hamstrings?', 'hamstring'),
    MapEntry('adductors?', 'adductors'),
    MapEntry('groin', 'adductors'),
    MapEntry('calves', 'calves'),
    MapEntry('calf', 'calves'),
    MapEntry('soleus', 'calves'),
    MapEntry('shins?', 'tibialis'),
  ]);
}
