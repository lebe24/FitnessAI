import 'package:fitness/data/services/coach/exercise_coach_service.dart';
import 'package:fitness/domain/coach/exercise_recommendation.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/fitness/view_models/exercise_coach_view_model.dart';
import 'package:flutter/material.dart';

/// Plain words for why the coach's own answer is not being shown.
String coachErrorText(ExerciseCoachError error) => switch (error) {
      ExerciseCoachError.offline => 'You are offline, so this is the app\'s own advice.',
      ExerciseCoachError.rateLimited => 'Too many requests just now. Showing the app\'s own advice.',
      ExerciseCoachError.premiumRequired =>
        'Your Pro access could not be confirmed. Showing the app\'s own advice.',
      ExerciseCoachError.server => 'The coach could not answer. Showing the app\'s own advice.',
    };

/// A line saying where an answer came from.
class CoachSource extends StatelessWidget {
  final CoachAnswer answer;
  const CoachSource({super.key, required this.answer});

  @override
  Widget build(BuildContext context) => Text(
        answer.error != null
            ? coachErrorText(answer.error!)
            : answer.fromModel
                ? 'Written by your AI coach'
                : 'The app\'s own advice',
        style: bodyText(11, color: kBodyMuted),
      );
}

/// What to lift today, why, and a way to ask for more.
class CoachCard extends StatelessWidget {
  final ExerciseCoachViewModel vm;
  final void Function(SetPrescription prescription, {required bool alternative}) onUse;

  const CoachCard({super.key, required this.vm, required this.onUse});

  static Color _colour(CoachAction a) => switch (a) {
        CoachAction.addWeight || CoachAction.addReps || CoachAction.addSet => kBodyLime,
        CoachAction.hold || CoachAction.timed => kBodyBlue,
        CoachAction.easeOff => kBodyAmber,
        CoachAction.findWeight => kBodySoft,
      };

  @override
  Widget build(BuildContext context) {
    final rec = vm.recommendation;
    return BodyCard(
      borderColor: kBodyLime.withValues(alpha: 0.28),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 16, color: kBodyLime),
              const SizedBox(width: 8),
              Expanded(child: Text('Coach', style: bodyHeading(15))),
              if (rec != null && !vm.loading) StatusPill(label: rec.badge, color: _colour(rec.action)),
            ],
          ),
          const SizedBox(height: 12),
          if (vm.unavailable)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Could not read your training log, so there is no advice yet.',
                    style: bodyText(12.5, color: kBodyMuted, height: 1.45)),
                const SizedBox(height: 10),
                BodyButton(label: 'Try again', filled: false, onPressed: vm.load),
              ],
            )
          else if (rec == null || vm.loading)
            const SizedBox(
              height: 64,
              child: Center(
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kBodyLime)),
              ),
            )
          else ...[
            Text(rec.target.label, style: bodyHeading(21)),
            const SizedBox(height: 6),
            Text(rec.reason, style: bodyText(12.5, color: kBodyMuted, height: 1.5)),
            if (rec.alternative != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                decoration: BoxDecoration(color: kBodyBg, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Or ${rec.alternative!.label}', style: bodyText(13, weight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(rec.alternativeReason ?? '', style: bodyText(11.5, color: kBodyMuted, height: 1.4)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => onUse(rec.alternative!, alternative: true),
                      child: Text('Use', style: bodyText(13, color: kBodyLime, weight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
            if (vm.why != null) ...[
              const SizedBox(height: 12),
              Text(vm.why!.note, style: bodyText(13, color: kBodySoft, height: 1.55)),
              const SizedBox(height: 6),
              CoachSource(answer: vm.why!),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: BodyButton(label: 'Use this', onPressed: () => onUse(rec.target, alternative: false)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BodyButton(
                    label: vm.why == null ? 'Ask the coach' : 'Ask again',
                    filled: false,
                    busy: vm.busy == CoachAsk.why,
                    onPressed: vm.busy == null ? vm.askWhy : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
