import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/muscle_focus.dart';
import 'package:fitness/domain/coach/exercise_catalog.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/muscle_coverage.dart';
import 'package:fitness/domain/models/session_volume.dart';
import 'package:fitness/domain/models/workout_plan.dart';

/// How the user says they feel today.
enum Soreness { fresh, aBitSore, verySore }

/// Whether more work fits this session.
enum VolumeVerdict { room, enough, stop }

/// Hard sets for one muscle group: today, the six days before, and the weekly
/// target for the user's goal.
class MuscleVolume {
  final MuscleGroup group;
  final double today;
  final double earlier;
  final double target;
  const MuscleVolume({required this.group, required this.today, required this.earlier, required this.target});

  double get week => today + earlier;

  /// Sets still short of the weekly target.
  double get deficit => target > week ? target - week : 0;
}

/// `7` rather than `7.0`; `4.5` stays `4.5`.
String formatSets(double sets) =>
    sets == sets.roundToDouble() ? sets.toStringAsFixed(0) : sets.toStringAsFixed(1);

/// Whether today already has enough work. Rules, not a model: this is the part
/// that can tell someone to stop.
class SessionLoad {
  /// More than this many sets for one muscle in a session adds little.
  static const maxSetsPerMuscle = 10;

  /// More than this many sets in a session is a long session.
  static const maxSessionSets = 24;

  /// A week this far over target is where soreness outruns progress.
  static const overTargetFactor = 1.5;

  /// Every group's volume, trained today or not.
  final Map<MuscleGroup, MuscleVolume> volumes;
  final int totalSets;
  final VolumeVerdict verdict;
  final Soreness? soreness;
  final String headline;
  final String advice;

  /// Sets that still fit today. Zero unless the verdict is [VolumeVerdict.room].
  final int roomSets;

  const SessionLoad({
    required this.volumes,
    required this.totalSets,
    required this.verdict,
    required this.soreness,
    required this.headline,
    required this.advice,
    required this.roomSets,
  });

  /// The groups today's session trains, most sets first.
  List<MuscleVolume> get trainedToday => [
        for (final v in volumes.values)
          if (v.today > 0) v
      ]..sort((a, b) => b.today.compareTo(a.today));

  static const painNote = 'Sharp or joint pain is not soreness: stop if you feel it.';

  /// [today] is the session in progress. Rows already logged for today in
  /// [sessions] are left out, so an exercise logged mid-session is not counted
  /// twice.
  static SessionLoad analyse({
    required List<Exercise> today,
    required List<WorkoutSessionModel> sessions,
    required DateTime now,
    GoalType? goal,
    Soreness? soreness,
  }) {
    final day = DateTime(now.year, now.month, now.day);
    final from = day.subtract(const Duration(days: 6));

    final todaySets = <MuscleGroup, double>{};
    var total = 0;
    for (final e in today) {
      total += e.sets;
      _add(todaySets, e.name, e.notes ?? '', e.sets.toDouble());
    }

    final earlier = <MuscleGroup, double>{};
    for (final s in sessions) {
      final d = DateTime(s.sessionDate.year, s.sessionDate.month, s.sessionDate.day);
      if (d.isBefore(from) || !d.isBefore(day)) continue;
      // One day can hold the same exercise twice (logged, then saved again);
      // identical set lists count once.
      final seen = <String>{};
      for (final ex in SessionVolume.exercisesOf(s)) {
        final signature = '${ex.name.toLowerCase()}|'
            '${ex.sets.map((x) => '${x.reps}:${x.durationSec}:${x.weightKg}').join(',')}';
        if (!seen.add(signature)) continue;
        _add(earlier, ex.name, '', ex.performedSets.toDouble());
      }
    }

    final volumes = {
      for (final g in MuscleGroup.values)
        g: MuscleVolume(
          group: g,
          today: todaySets[g] ?? 0,
          earlier: earlier[g] ?? 0,
          target: MuscleFocus.targetSets(g, goal),
        ),
    };

    final trained = [for (final v in volumes.values) if (v.today > 0) v];
    // A group only counts as trained for the verdict when today works it
    // directly, not just as an assistant to something else.
    final main = [for (final v in trained) if (v.today >= 2) v];

    VolumeVerdict verdict;
    String headline;
    String advice;
    var room = 0;

    MuscleVolume? over;
    for (final v in main) {
      if (v.week >= v.target * overTargetFactor && (over == null || v.week / v.target > over.week / over.target)) {
        over = v;
      }
    }
    MuscleVolume? heavyToday;
    for (final v in main) {
      if (v.today > maxSetsPerMuscle && (heavyToday == null || v.today > heavyToday.today)) heavyToday = v;
    }

    if (soreness == Soreness.verySore) {
      verdict = VolumeVerdict.stop;
      headline = 'Call it here';
      advice = 'You said you are very sore. Rest or very light movement will help more than another exercise. $painNote';
    } else if (over != null) {
      verdict = VolumeVerdict.stop;
      headline = '${over.group.label} has had plenty this week';
      advice = '${formatSets(over.week)} sets against a target of about ${formatSets(over.target)}. '
          'More now mostly adds soreness. $painNote';
    } else if (total > maxSessionSets) {
      verdict = VolumeVerdict.enough;
      headline = 'Enough for today';
      advice = 'This session is already $total sets. Finishing well beats adding more. You can still add one if you want.';
    } else if (heavyToday != null) {
      verdict = VolumeVerdict.enough;
      headline = 'Enough for today';
      advice = '${heavyToday.group.label} gets ${formatSets(heavyToday.today)} sets today, and extra sets add little '
          'past $maxSetsPerMuscle. You can still add one if you want.';
    } else if (main.isNotEmpty && main.every((v) => v.week >= v.target)) {
      verdict = VolumeVerdict.enough;
      headline = 'Enough for today';
      advice = 'With today, every muscle you are training is at its weekly target. You can still add one if you want.';
    } else {
      verdict = VolumeVerdict.room;
      headline = 'Room for a bit more';
      final short = [for (final v in main) if (v.deficit > 0) v]..sort((a, b) => b.deficit.compareTo(a.deficit));
      advice = short.isEmpty
          ? 'One more exercise would fit this session.'
          : '${short.first.group.label} will be at ${formatSets(short.first.week)} of about '
              '${formatSets(short.first.target)} sets this week. One more exercise would fit.';
      room = (maxSessionSets - total).clamp(0, 12);
    }

    if (soreness == Soreness.aBitSore && verdict != VolumeVerdict.stop) {
      advice = '$advice Since you are a bit sore, keep extras light and pick muscles you have not trained today. $painNote';
      room = room.clamp(0, 6);
    }

    return SessionLoad(
      volumes: volumes,
      totalSets: total,
      verdict: verdict,
      soreness: soreness,
      headline: headline,
      advice: advice,
      roomSets: room,
    );
  }

  /// The first muscle named does the work (a full set); the rest assist (half).
  /// A group reached by two muscles of one exercise is counted once.
  static void _add(Map<MuscleGroup, double> into, String name, String notes, double sets) {
    if (sets <= 0) return;
    var slugs = MuscleCoverage.musclesFor(name: name, notes: notes);
    // Logged rows carry no coaching text, and some names ("Cable Fly") say no
    // muscle. A name the catalogue knows still counts.
    if (slugs.isEmpty) {
      final key = ExerciseHistory.keyFor(name);
      for (final c in kExerciseCatalog) {
        if (ExerciseHistory.keyFor(c.name) == key) {
          slugs = MuscleCoverage.musclesFor(name: name, notes: c.notes);
          break;
        }
      }
    }
    final share = <MuscleGroup, double>{};
    for (var i = 0; i < slugs.length; i++) {
      final g = MuscleGroup.forSlug(slugs[i]);
      if (g == null) continue;
      final w = i == 0 ? 1.0 : 0.5;
      if (w > (share[g] ?? 0)) share[g] = w;
    }
    share.forEach((g, w) => into[g] = (into[g] ?? 0) + sets * w);
  }
}
