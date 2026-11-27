import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/analytics/energy_analytics.dart';
import 'package:fitness/domain/energy/energy_session.dart';
import 'package:fitness/ui/features/energy/energy_services.dart';
import 'package:fitness/ui/features/energy/view_models/energy_chat_controller.dart';
import 'package:fitness/ui/features/energy/views/energy_chat_sheet.dart';
import 'package:flutter/material.dart';

/// Opens the chat for [session], offering Pro first to those without it.
/// [source] is `session` or `finished`.
Future<void> openEnergyChat(
  BuildContext context, {
  required EnergyServices services,
  required WorkoutSessionModel session,
  bool imperial = false,
  String source = 'session',
  EnergyAnalytics analytics = const EnergyAnalytics(),
}) async {
  if (!services.allowed()) {
    analytics.lockedTapped();
    if (!await services.unlock(context) || !context.mounted) return;
  }
  double? weight;
  try {
    // The bot asks when this cannot be read in good time.
    weight = await services.weightKg().timeout(const Duration(seconds: 3));
    await services.bot.loaded;
  } catch (_) {}
  if (!context.mounted) return;
  analytics.opened(source);
  await showEnergyChat(
    context,
    facts: EnergyFacts(session: EnergySession.of(session), weightKg: weight, imperial: imperial),
    responder: services.responder,
    bot: services.bot.value,
  );
}
