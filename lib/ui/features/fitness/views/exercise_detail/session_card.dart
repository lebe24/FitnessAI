import 'package:fitness/data/services/coach/exercise_coach_service.dart';
import 'package:fitness/domain/coach/exercise_catalog.dart';
import 'package:fitness/domain/coach/session_load.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/fitness/view_models/exercise_coach_view_model.dart';
import 'package:fitness/ui/features/fitness/views/exercise_detail/coach_card.dart';
import 'package:flutter/material.dart';

String sorenessLabel(Soreness s) => switch (s) {
      Soreness.fresh => 'Fresh',
      Soreness.aBitSore => 'A bit sore',
      Soreness.verySore => 'Very sore',
    };

Color _verdictColour(VolumeVerdict v) => switch (v) {
      VolumeVerdict.room => kBodyLime,
      VolumeVerdict.enough => kBodyAmber,
      VolumeVerdict.stop => kBodyRed,
    };

/// Whether today has enough work, and what could be added.
class SessionCard extends StatelessWidget {
  final ExerciseCoachViewModel vm;

  /// Null when this page cannot change the workout; suggestions are then shown
  /// without an add button.
  final void Function(List<Suggestion> picks, String source)? onAdd;

  const SessionCard({super.key, required this.vm, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final load = vm.session;
    if (load == null || vm.loading || vm.unavailable) return const SizedBox.shrink();
    final past = load.verdict != VolumeVerdict.room;
    final answer = vm.lastAnswer;
    final listed = vm.suggestions ?? vm.workout;

    return BodyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s session', style: bodyHeading(15)),
          const SizedBox(height: 10),
          Text('How do you feel?', style: bodyText(12, color: kBodyMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in Soreness.values)
                _CheckChip(
                  label: sorenessLabel(s),
                  selected: vm.soreness == s,
                  // Tapping the chosen answer again clears it.
                  onTap: () => vm.setSoreness(vm.soreness == s ? null : s),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (final v in load.trainedToday.take(5)) _MuscleRow(v),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: _verdictColour(load.verdict), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(load.headline,
                    style: bodyText(14, color: _verdictColour(load.verdict), weight: FontWeight.w700)),
              ),
              Text('${load.totalSets} sets today', style: bodyText(11.5, color: kBodyMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(load.advice, style: bodyText(12.5, color: kBodySoft, height: 1.5)),
          const SizedBox(height: 14),
          if (past) ...[
            Text('Want to do more anyway?', style: bodyText(11.5, color: kBodyMuted)),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: BodyButton(
              label: 'Suggest an exercise',
              icon: Icons.add_rounded,
              filled: !past,
              busy: vm.busy == CoachAsk.suggest,
              onPressed: vm.busy == null ? vm.suggest : null,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: BodyButton(
              label: 'Generate extra workout',
              icon: Icons.auto_awesome_rounded,
              filled: false,
              busy: vm.busy == CoachAsk.workout,
              onPressed: vm.busy == null ? vm.generateWorkout : null,
            ),
          ),
          if (listed != null && answer != null) ...[
            const SizedBox(height: 16),
            Text(vm.workout != null ? 'Extra workout' : 'Suggestions', style: bodyHeading(14)),
            if (answer.fromModel && answer.sessionAdvice.isNotEmpty && answer.sessionAdvice != load.advice) ...[
              const SizedBox(height: 6),
              Text(answer.sessionAdvice, style: bodyText(12.5, color: kBodySoft, height: 1.5)),
            ],
            const SizedBox(height: 4),
            CoachSource(answer: answer),
            const SizedBox(height: 10),
            if (listed.isEmpty)
              Text('Nothing else to suggest for this session.', style: bodyText(12.5, color: kBodyMuted))
            else ...[
              for (final s in listed)
                _SuggestionRow(
                  suggestion: s,
                  onAdd: onAdd == null || vm.workout != null ? null : () => onAdd!([s], 'suggestion'),
                ),
              if (vm.workout != null && onAdd != null)
                SizedBox(
                  width: double.infinity,
                  child: BodyButton(
                    label: 'Add all ${listed.length}',
                    onPressed: () => onAdd!(listed, 'workout'),
                  ),
                ),
            ],
          ],
          const SizedBox(height: 12),
          Text('Guidance from your logs, not medical advice.', style: bodyText(10.5, color: kBodyMuted)),
        ],
      ),
    );
  }
}

class _CheckChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CheckChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? kBodyLime : kBodyChip,
              borderRadius: BorderRadius.circular(17),
              border: selected ? null : Border.all(color: kBodyBorder),
            ),
            child: Center(
              widthFactor: 1,
              child: Text(label, style: bodyText(12.5, color: selected ? kBodyBg : kBodySoft)),
            ),
          ),
        ),
      );
}

class _MuscleRow extends StatelessWidget {
  final MuscleVolume v;
  const _MuscleRow(this.v);

  @override
  Widget build(BuildContext context) {
    final ratio = v.target == 0 ? 0.0 : v.week / v.target;
    final colour = ratio >= SessionLoad.overTargetFactor
        ? kBodyRed
        : ratio >= 1
            ? kBodyAmber
            : kBodyLime;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(v.group.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(12.5, weight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${formatSets(v.today)} today · ${formatSets(v.week)}/${formatSets(v.target)} this week',
                        style: bodyText(11, color: kBodyMuted)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: kBodyUntrained,
              color: colour,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final Suggestion suggestion;
  final VoidCallback? onAdd;
  const _SuggestionRow({required this.suggestion, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    final weight = s.weightKg == null ? '' : ' @ ${formatKg(s.weightKg!)} kg';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(color: kBodyBg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.exercise.name, style: bodyText(13.5, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${s.sets} × ${s.reps}$weight', style: bodyText(12, color: kBodyLime, weight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(s.why, style: bodyText(11.5, color: kBodyMuted, height: 1.4)),
              ],
            ),
          ),
          if (onAdd != null)
            TextButton(
              onPressed: onAdd,
              child: Text('Add', style: bodyText(13, color: kBodyLime, weight: FontWeight.w700)),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}
