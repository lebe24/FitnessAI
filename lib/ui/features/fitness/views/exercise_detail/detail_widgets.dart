import 'package:fitness/domain/models/muscle.dart';
import 'package:fitness/domain/models/muscle_coverage.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:flutter/material.dart';

/// A round button as in the design's header.
class RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const RoundButton({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kBodyCard,
              shape: BoxShape.circle,
              border: Border.all(color: kBodyBorder),
            ),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
        ),
      );
}

class DetailHeader extends StatelessWidget {
  final VoidCallback onMenu;
  const DetailHeader({super.key, required this.onMenu});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            RoundButton(
              icon: Icons.arrow_back_ios_new_rounded,
              label: 'Back',
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const Spacer(),
            RoundButton(icon: Icons.more_horiz_rounded, label: 'More options', onTap: onMenu),
          ],
        ),
      );
}

/// The exercise's name and the muscles it trains.
class ExerciseHeading extends StatelessWidget {
  final Exercise exercise;
  const ExerciseHeading({super.key, required this.exercise});

  static List<String> muscleNames(Exercise e) => [
        for (final slug in MuscleCoverage.musclesFor(name: e.name, notes: e.notes ?? '').take(4))
          if (Muscle.bySlug(slug) != null) Muscle.bySlug(slug)!.name
      ];

  @override
  Widget build(BuildContext context) {
    final muscles = muscleNames(exercise);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(exercise.name, style: bodyHeading(24)),
        if (muscles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in muscles)
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: kBodyChip,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBodyBorder),
                  ),
                  child: Center(widthFactor: 1, child: Text(m, style: bodyText(12, color: kBodySoft))),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Sets, reps and the last weight lifted. Tapping it logs the sets.
class DetailStats extends StatelessWidget {
  final int sets;
  final String reps;

  /// `28 kg`, or null when nothing is logged yet.
  final String? lastWeight;

  /// The last weight is part of exercise history, a Pro feature.
  final bool lastWeightLocked;
  final String? target;
  final VoidCallback onTapLog;

  const DetailStats({
    super.key,
    required this.sets,
    required this.reps,
    required this.lastWeight,
    required this.onTapLog,
    this.lastWeightLocked = false,
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Log your sets',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTapLog,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
          decoration: BoxDecoration(
            color: kBodyCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: kBodyBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _Figure('$sets', 'Sets')),
                  Expanded(child: _Figure(reps, 'Reps')),
                  Expanded(
                    child: lastWeightLocked
                        ? const _Figure(null, 'Last weight')
                        : _Figure(lastWeight ?? '–', 'Last weight'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                target == null ? 'Tap to log your sets' : 'Plan target $target · Tap to log your sets',
                textAlign: TextAlign.center,
                style: bodyText(11, color: kBodyLime, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  /// Null shows a lock.
  final String? value;
  final String label;
  const _Figure(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SizedBox(
            height: 30,
            child: Center(
              child: value == null
                  ? const Icon(Icons.lock_outline_rounded, size: 18, color: kBodyMuted, semanticLabel: 'Pro')
                  : FittedBox(fit: BoxFit.scaleDown, child: Text(value!, style: bodyHeading(22))),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: bodyText(11, color: kBodyMuted)),
        ],
      );
}

/// The amber note: the plan's own coaching cue for this movement.
class SafetyTipCard extends StatelessWidget {
  final String? notes;
  const SafetyTipCard({super.key, this.notes});

  static const fallback = 'Follow instructions carefully to avoid injury and maximize effectiveness.';

  /// A plan note reads `muscles | cue`; the cue is the advice.
  static String tipFor(String? notes) {
    if (notes == null) return fallback;
    final parts = notes.split('|');
    if (parts.length < 2) return fallback;
    final cue = parts.sublist(1).join('|').trim();
    // A saved log puts set data where the cue was; that is not advice.
    return cue.isEmpty || RegExp(r'set\s*\d+\s*:', caseSensitive: false).hasMatch(cue) ? fallback : cue;
  }

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2108),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF5C4710)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 20, color: kBodyAmber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Safety tip', style: bodyText(13, color: kBodyAmber, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(tipFor(notes),
                      style: bodyText(12, color: const Color(0xFFE8D7A8), weight: FontWeight.w400, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      );
}

class CompleteExerciseButton extends StatelessWidget {
  final VoidCallback onComplete;
  const CompleteExerciseButton({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
        child: Semantics(
          button: true,
          child: GestureDetector(
            onTap: onComplete,
            child: Container(
              height: 56,
              decoration: BoxDecoration(color: kBodyLime, borderRadius: BorderRadius.circular(28)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, color: kBodyBg, size: 19),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('Complete exercise',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bodyHeading(15, color: kBodyBg).copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
