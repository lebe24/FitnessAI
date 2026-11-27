import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/workout_log/exercise_history_service.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/analytic/views/body/body_actions.dart';
import 'package:fitness/ui/features/analytic/views/session_detail_page.dart';
import 'package:fitness/ui/features/energy/energy_services.dart';
import 'package:flutter/material.dart';

/// [saved] as the database now holds it, which adds anything written since the
/// save, such as the coach's feedback. [saved] itself when that cannot be read.
WorkoutSessionModel latestCopy(WorkoutSessionModel saved, List<WorkoutSessionModel>? all) {
  if (saved.id == null) return saved;
  for (final s in all ?? const <WorkoutSessionModel>[]) {
    // An older copy would be missing what was just saved.
    if (s.id == saved.id && s.workoutLogs.length >= saved.workoutLogs.length) return s;
  }
  return saved;
}

/// Opens the page of a workout just finished, with the energy bot showing.
Future<void> openFinishedSession(
  BuildContext context, {
  required WorkoutSessionModel saved,
  Future<List<WorkoutSessionModel>?> Function()? sessions,
  Future<bool?> Function()? imperial,
  EnergyServices? energy,
}) async {
  List<WorkoutSessionModel>? all;
  var pounds = false;
  try {
    final read = sessions ??
        () {
          final history = sl<ExerciseHistoryService>()..invalidate();
          return history.sessions();
        };
    // Not worth keeping someone waiting for.
    all = await read().timeout(const Duration(seconds: 5));
  } catch (_) {}
  try {
    pounds = await (imperial ?? BodyUnitPref.load)() ?? false;
  } catch (_) {}
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => SessionDetailPage(
      session: latestCopy(saved, all),
      imperial: pounds,
      history: all ?? const [],
      openEnergy: true,
      energy: energy,
    ),
  ));
}
