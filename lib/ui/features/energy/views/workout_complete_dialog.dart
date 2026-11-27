import 'package:fitness/domain/energy/bot_settings.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/energy/view_models/energy_chat_controller.dart';
import 'package:fitness/ui/features/energy/views/bot_mascot.dart';
import 'package:fitness/ui/features/energy/views/energy_widgets.dart';
import 'package:flutter/material.dart';

/// The bot popping up once a workout is finished and saved. True when the user
/// wants to see the energy they used.
Future<bool> showWorkoutCompleteDialog(
  BuildContext context, {
  required BotSettings bot,
  required int exercises,
  required int minutes,
}) async {
  final see = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (_) => WorkoutCompleteDialog(bot: bot, exercises: exercises, minutes: minutes),
  );
  return see ?? false;
}

class WorkoutCompleteDialog extends StatelessWidget {
  final BotSettings bot;
  final int exercises;
  final int minutes;

  const WorkoutCompleteDialog({
    super.key,
    required this.bot,
    required this.exercises,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) {
    final done = [
      if (exercises > 0) '$exercises ${exercises == 1 ? 'exercise' : 'exercises'}',
      if (minutes > 0) '$minutes min',
    ].join(' · ');

    Widget button(String label, bool value, {required bool primary}) => Expanded(
          child: Material(
            color: primary ? kBodyLime : Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: primary ? kBodyLime : Colors.white.withValues(alpha: 0.1)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(value),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: bodyHeading(13, color: primary ? Colors.black : Colors.white60)),
              ),
            ),
          ),
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: SingleChildScrollView(
        child: PopIn(
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 52),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 20),
                decoration: BoxDecoration(
                  color: kBodyCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kBodyBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Workout complete!', textAlign: TextAlign.center, style: bodyHeading(20)),
                    if (done.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(done, style: bodyText(12, color: kBodyLime, weight: FontWeight.w700)),
                    ],
                    const SizedBox(height: 12),
                    Text('${bot.name} can show you the energy you used in this session.',
                        textAlign: TextAlign.center,
                        style: bodyText(13, color: kBodySoft, height: 1.5)),
                    const SizedBox(height: 20),
                    Row(children: [
                      button('Not now', false, primary: false),
                      const SizedBox(width: 12),
                      button('See my energy', true, primary: true),
                    ]),
                  ],
                ),
              ),
              BotMascotView(
                  mascot: bot.mascot, size: 108, mood: BotMood.cheer, semanticLabel: bot.name),
            ],
          ),
        ),
      ),
    );
  }
}
