import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/energy/energy_effort.dart';
import 'package:fitness/domain/models/session_volume.dart';

class EnergyExercise {
  final String name;

  /// Performed sets, e.g. `10 x 60 kg`.
  final List<String> sets;
  const EnergyExercise(this.name, [this.sets = const []]);
}

/// A saved session reduced to what the energy bot talks about.
class EnergySession {
  final String title;

  /// Null when none was recorded; the bot then asks.
  final int? minutes;
  final int sets;
  final int bigLiftSets;
  final double volumeKg;
  final List<EnergyExercise> exercises;

  const EnergySession({
    required this.title,
    this.minutes,
    this.sets = 0,
    this.bigLiftSets = 0,
    this.volumeKg = 0,
    this.exercises = const [],
  });

  /// Whether there is a workout here to talk about.
  static bool hasWorkout(WorkoutSessionModel s) => s.workoutLogs.isNotEmpty;

  factory EnergySession.of(WorkoutSessionModel session) {
    var sets = 0, big = 0;
    var volume = 0.0;
    final exercises = <EnergyExercise>[];
    for (final e in SessionVolume.exercisesOf(session)) {
      final done = [for (final s in e.sets) if (s.wasPerformed) s];
      if (done.isEmpty) continue;
      sets += done.length;
      if (EffortRating.isBigLift(e.name)) big += done.length;
      volume += done.fold(0.0, (t, s) => t + s.volumeKg);
      exercises.add(EnergyExercise(e.name, [for (final s in done) _label(s)]));
    }
    final label = session.dayLabel?.trim();
    final minutes = session.durationMins;
    return EnergySession(
      title: label == null || label.isEmpty ? 'Workout' : label,
      minutes: minutes != null && minutes > 0 ? minutes : null,
      sets: sets,
      bigLiftSets: big,
      volumeKg: volume,
      exercises: exercises,
    );
  }

  static String _label(LoggedSet s) {
    if (s.durationSec != null) return '${s.durationSec} sec';
    final kg = s.weightKg;
    if (kg == null || kg == 0) return '${s.reps} reps';
    return '${s.reps} x ${kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg} kg';
  }
}
