import 'package:fitness/domain/body/body_advice.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:flutter/material.dart';

/// The coach's advice on the goal.
class AdviceCard extends StatelessWidget {
  final BodyAdvice? advice;
  final bool hasGoal;
  final bool loading;
  final BodyTrackingError? error;
  final VoidCallback onRefresh;
  final VoidCallback onSetGoal;

  const AdviceCard({
    super.key,
    required this.advice,
    required this.hasGoal,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onSetGoal,
  });

  @override
  Widget build(BuildContext context) {
    return BodyCard(
      borderColor: kBodyLime.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 17, color: kBodyLime),
              const SizedBox(width: 8),
              Expanded(child: Text('Coach advice', style: bodyHeading(16))),
              if (hasGoal)
                Semantics(
                  button: true,
                  label: 'Refresh advice',
                  child: GestureDetector(
                    onTap: loading ? null : onRefresh,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: kBodyBorder),
                      ),
                      child: loading
                          ? const Padding(
                              padding: EdgeInsets.all(9),
                              child: CircularProgressIndicator(strokeWidth: 2, color: kBodyLime),
                            )
                          : const Icon(Icons.refresh_rounded, size: 17, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasGoal)
            _Prompt(
              text: 'Set a goal and your coach will read your weight, measurements and training, '
                  'then tell you what to change.',
              button: BodyButton(label: 'Set a goal', onPressed: onSetGoal),
            )
          else if (advice == null && loading)
            const _Skeleton()
          else if (advice == null && error != null)
            _Prompt(text: _errorText(error!), button: BodyButton(label: 'Try again', onPressed: onRefresh))
          else if (advice == null)
            _Prompt(
              text: 'Get advice built from your goal, your logs and the muscles you train.',
              button: BodyButton(label: 'Get advice', icon: Icons.auto_awesome_rounded, onPressed: onRefresh),
            )
          else
            _Content(advice: advice!, error: error, stale: loading),
        ],
      ),
    );
  }

  static String _errorText(BodyTrackingError e) => switch (e) {
        BodyTrackingError.premiumRequired => 'Coach advice is part of BeFit Pro.',
        BodyTrackingError.rateLimited => 'That was a lot of requests. Try again in a minute.',
        BodyTrackingError.offline => 'You are offline. Advice needs a connection.',
        BodyTrackingError.server => 'Your coach could not answer just now. Try again shortly.',
      };
}

class _Content extends StatelessWidget {
  final BodyAdvice advice;
  final BodyTrackingError? error;
  final bool stale;
  const _Content({required this.advice, required this.error, required this.stale});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: stale ? 0.6 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(advice.headline, style: bodyHeading(17)),
          const SizedBox(height: 8),
          Text(advice.summary, style: bodyText(13, color: Colors.white.withValues(alpha: 0.82), height: 1.5)),
          const SizedBox(height: 14),
          for (var i = 0; i < advice.actions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: kBodyLime.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}', style: bodyText(11.5, color: kBodyLime, weight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(advice.actions[i].title, style: bodyText(13.5, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(advice.actions[i].detail, style: bodyText(12.5, color: kBodyMuted, height: 1.45)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(AdviceCard._errorText(error!), style: bodyText(12, color: kBodyAmber)),
            ),
          const SizedBox(height: 2),
          Text(
            '${advice.fromModel ? 'Written by your coach' : 'Based on your numbers'} · ${shortDate(advice.generatedAt)}',
            style: bodyText(11, color: kBodyMuted),
          ),
          const SizedBox(height: 4),
          Text(advice.disclaimer, style: bodyText(10.5, color: kBodyMuted.withValues(alpha: 0.8), height: 1.4)),
        ],
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  final String text;
  final Widget button;
  const _Prompt({required this.text, required this.button});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: bodyText(13, color: kBodyMuted, height: 1.5)),
          const SizedBox(height: 14),
          button,
        ],
      );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w) => Container(
          height: 12,
          width: w,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(6)),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [bar(220), bar(300), bar(260), bar(180)],
    );
  }
}
