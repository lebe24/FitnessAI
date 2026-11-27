import 'dart:async';

import 'package:fitness/domain/energy/bot_settings.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/energy/view_models/energy_chat_controller.dart';
import 'package:fitness/ui/features/energy/views/bot_mascot.dart';
import 'package:fitness/ui/features/energy/views/energy_widgets.dart';
import 'package:flutter/material.dart';

/// The bot peeking in at the corner of a session, offering to work out its
/// energy. Closing the bubble leaves the mascot there to tap later.
class EnergyNudge extends StatefulWidget {
  final BotSettings bot;
  final bool locked;

  /// Puts the bubble above the mascot, for phones too narrow to fit it beside.
  final bool stacked;
  final VoidCallback onOpen;
  final Duration delay;

  const EnergyNudge({
    super.key,
    required this.bot,
    required this.onOpen,
    this.locked = false,
    this.stacked = false,
    this.delay = const Duration(milliseconds: 600),
  });

  @override
  State<EnergyNudge> createState() => _EnergyNudgeState();
}

class _EnergyNudgeState extends State<EnergyNudge> {
  Timer? _timer;
  bool _shown = false;
  bool _bubble = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () => setState(() => _shown = true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shown) return const SizedBox.shrink();

    final mascot = Semantics(
      button: true,
      label: 'Ask ${widget.bot.name} about your energy',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onOpen,
        child: BotMascotView(mascot: widget.bot.mascot, size: 72, mood: BotMood.greet),
      ),
    );
    final bubble = _bubble
        ? _Bubble(
            locked: widget.locked,
            onOpen: widget.onOpen,
            onDismiss: () => setState(() => _bubble = false),
          )
        : null;

    return PopIn(
      child: widget.stacked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [if (bubble != null) bubble, mascot],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                mascot,
                if (bubble != null)
                  Flexible(
                    child: Padding(padding: const EdgeInsets.only(left: 2, bottom: 32), child: bubble),
                  ),
              ],
            ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool locked;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;
  const _Bubble({required this.locked, required this.onOpen, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    const shape = BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomRight: Radius.circular(16),
      bottomLeft: Radius.circular(4),
    );
    return Material(
      color: kBodyRaised,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: shape,
        side: BorderSide(color: kBodyLime.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: shape,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 2, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What did you burn? 🔥',
                        style: bodyText(12.5, weight: FontWeight.w700, height: 1.3)),
                    if (locked)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: PremiumBadge(visible: true),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 15, color: kBodyMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
