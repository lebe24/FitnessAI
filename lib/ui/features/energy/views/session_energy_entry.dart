import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/ui/features/energy/energy_services.dart';
import 'package:fitness/ui/features/energy/views/energy_launcher.dart';
import 'package:fitness/ui/features/energy/views/energy_nudge.dart';
import 'package:flutter/material.dart';

/// The bot's place on a session page: the peeking mascot in the bottom corner,
/// and, after finishing a workout, the chat opened straight away.
class SessionEnergyEntry extends StatefulWidget {
  final EnergyServices services;
  final WorkoutSessionModel session;
  final bool imperial;
  final bool openNow;

  const SessionEnergyEntry({
    super.key,
    required this.services,
    required this.session,
    required this.imperial,
    this.openNow = false,
  });

  @override
  State<SessionEnergyEntry> createState() => _SessionEnergyEntryState();
}

class _SessionEnergyEntryState extends State<SessionEnergyEntry> {
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    if (widget.openNow) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open('finished'));
    }
  }

  Future<void> _open(String source) async {
    // A second tap while the chat is on its way would stack two.
    if (_opening || !mounted) return;
    _opening = true;
    try {
      await openEnergyChat(context,
          services: widget.services,
          session: widget.session,
          imperial: widget.imperial,
          source: source);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = widget.services;
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 361;
    return Align(
      alignment: Alignment.bottomLeft,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 0, 12),
          // Beside the Share button in the other corner, or above it when the
          // phone is too narrow for both.
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: narrow ? width - 24 : width - 156),
            child: ListenableBuilder(
              listenable: Listenable.merge([services.access, services.bot]),
              builder: (_, __) => EnergyNudge(
                bot: services.bot.value,
                locked: !services.allowed(),
                stacked: narrow,
                onOpen: () => _open('session'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
