import 'dart:async';

import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/energy/energy_estimate.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:flutter/material.dart';

const kEnergyOrange = Color(0xFFFF6B3D);

/// Springs its child in from a corner, once.
class PopIn extends StatelessWidget {
  final Widget child;
  final Alignment alignment;
  const PopIn({super.key, required this.child, this.alignment = Alignment.bottomLeft});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (_, v, c) => Opacity(
        opacity: v.clamp(0, 1),
        child: Transform.scale(scale: 0.8 + 0.2 * v, alignment: alignment, child: c),
      ),
      child: child,
    );
  }
}

class SpeechBubble extends StatelessWidget {
  final String text;
  final bool fromUser;

  /// A line under the bubble, e.g. that this is an offline answer.
  final String? note;
  const SpeechBubble(this.text, {super.key, this.fromUser = false, this.note});

  @override
  Widget build(BuildContext context) {
    const round = Radius.circular(20), tight = Radius.circular(6);
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: PopIn(
        alignment: fromUser ? Alignment.bottomRight : Alignment.bottomLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 290),
          child: Column(
            crossAxisAlignment: fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: fromUser ? kBodyLime : kBodyCard,
                  borderRadius: BorderRadius.only(
                    topLeft: round,
                    topRight: round,
                    bottomLeft: fromUser ? round : tight,
                    bottomRight: fromUser ? tight : round,
                  ),
                  border: Border.all(color: fromUser ? kBodyLime : kBodyBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                  child: Text(text,
                      style: bodyText(14, color: fromUser ? Colors.black : Colors.white, height: 1.45)),
                ),
              ),
              if (note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(note!, style: bodyText(11, color: kBodyMuted)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The same "is thinking" line the coach chat shows.
class ThinkingLine extends StatefulWidget {
  final String name;
  const ThinkingLine(this.name, {super.key});

  @override
  State<ThinkingLine> createState() => _ThinkingLineState();
}

class _ThinkingLineState extends State<ThinkingLine> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void initState() {
    super.initState();
    unawaited(_c.repeat(reverse: true));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: FadeTransition(
          opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
          child: Row(children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(color: kBodyLime, shape: BoxShape.circle),
            ),
            Flexible(
              child: Text('${widget.name} is thinking…',
                  style: bodyText(12, color: kBodyMuted).copyWith(fontStyle: FontStyle.italic)),
            ),
          ]),
        ),
      );
}

/// A tap-to-answer pill, as on the coach chat.
class ReplyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const ReplyChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: kBodyChip,
        shape: const StadiumBorder(side: BorderSide(color: kBodyBorder)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Text(label, style: bodyText(12.5, color: kBodySoft, weight: FontWeight.w600)),
          ),
        ),
      );
}

/// The answer: the calorie range, counting up, and what it was worked out from.
class EnergyResultCard extends StatelessWidget {
  final EnergyEstimate estimate;
  final bool imperial;
  const EnergyResultCard({super.key, required this.estimate, this.imperial = false});

  @override
  Widget build(BuildContext context) {
    final e = estimate;
    final still = MediaQuery.disableAnimationsOf(context);
    return PopIn(
      child: BodyCard(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        borderColor: kEnergyOrange.withValues(alpha: 0.45),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.local_fire_department_rounded, color: kEnergyOrange, size: 18),
              const SizedBox(width: 6),
              Text('ENERGY USED',
                  style: bodyText(11, color: kEnergyOrange, weight: FontWeight.w700)
                      .copyWith(letterSpacing: 1)),
            ]),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: still ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('${(e.lowKcal * v).round()}–${(e.highKcal * v).round()}',
                    style: bodyHeading(44, color: kBodyLime)),
              ),
            ),
            Text('kcal · estimated', style: bodyText(12, color: kBodyMuted)),
            const SizedBox(height: 14),
            Row(children: [
              _Fact(Icons.timer_outlined, kBodyBlue, '${e.minutes} min', 'Time'),
              const SizedBox(width: 8),
              _Fact(Icons.monitor_weight_outlined, kBodyGreen,
                  BodyUnits.weight(e.weightKg, imperial: imperial), 'You'),
              const SizedBox(width: 8),
              _Fact(Icons.bolt_rounded, kBodyAmber, e.effort.level.label, 'Effort'),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _Fact(this.icon, this.color, this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: kBodyBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBodyBorder),
          ),
          child: Column(children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(height: 5),
            FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: bodyHeading(13.5))),
            const SizedBox(height: 2),
            Text(label, style: bodyText(10.5, color: kBodyMuted)),
          ]),
        ),
      );
}
