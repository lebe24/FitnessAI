import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/goal_progress.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:flutter/material.dart';

/// The user's goal and how it is going.
class GoalCard extends StatelessWidget {
  final GoalProgress progress;
  final bool imperial;
  final DateTime now;
  final VoidCallback onSetGoal;
  final VoidCallback onLogWeight;

  const GoalCard({
    super.key,
    required this.progress,
    required this.imperial,
    required this.now,
    required this.onSetGoal,
    required this.onLogWeight,
  });

  @override
  Widget build(BuildContext context) {
    final goal = progress.goal;
    if (goal == null) return _NoGoal(onSetGoal: onSetGoal);

    final color = statusColor(progress.status);
    final t = progress.trend;
    final hasTarget = goal.targetWeightKg != null;

    return BodyCard(
      borderColor: color.withValues(alpha: 0.3),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.07), kBodyCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon(goal.type), size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(goal.type.label, style: bodyHeading(16))),
              StatusPill(label: statusLabel(progress.status), color: color),
            ],
          ),
          const SizedBox(height: 16),
          if (hasTarget) ...[
            // Scales down rather than overflow on a narrow phone or a long number.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(weightText(t.currentKg ?? goal.startWeightKg, imperial), style: bodyHeading(28)),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('→ ${weightText(goal.targetWeightKg, imperial)}',
                        style: bodyText(15, color: kBodySoft, weight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Bar(value: (progress.percentComplete ?? 0) / 100, color: color),
            const SizedBox(height: 6),
            Text(
              progress.percentComplete == null
                  ? 'Log your weight to see progress'
                  : '${progress.percentComplete}% of the way from ${weightText(goal.startWeightKg, imperial)}',
              style: bodyText(12, color: kBodySoft),
            ),
          ] else ...[
            Text(
              t.currentKg == null ? 'Log your weight to start' : weightText(t.currentKg, imperial),
              style: bodyHeading(28),
            ),
            const SizedBox(height: 4),
            Text(
              goal.type == GoalType.buildMuscle
                  ? 'Building muscle is measured by training and measurements, not the scale alone.'
                  : 'Holding steady. Weigh in a few times a week to catch drift early.',
              style: bodyText(12.5, color: kBodySoft, height: 1.45),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(
                label: 'This week',
                value: t.weeklyKg == null ? '–' : signedWeight(t.weeklyKg!, imperial),
              ),
              const SizedBox(width: 10),
              _Stat(
                label: 'Planned',
                value: progress.plannedRateKg == null || progress.plannedRateKg == 0
                    ? '–'
                    : '${BodyUnits.weight(progress.plannedRateKg!, imperial: imperial)}/wk',
              ),
              const SizedBox(width: 10),
              _Stat(label: 'Reach it', value: _eta()),
            ],
          ),
          if (progress.calorieAdjustment != null && progress.calorieAdjustment != 0) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_fire_department_rounded, size: 15, color: kBodyAmber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'About ${progress.calorieAdjustment!.abs()} kcal a day '
                    '${progress.calorieAdjustment! < 0 ? 'below' : 'above'} maintenance.',
                    style: bodyText(12.5, color: Colors.white.withValues(alpha: 0.85), height: 1.4),
                  ),
                ),
              ],
            ),
          ],
          if (progress.status == ProgressStatus.tooFast) ...[
            const SizedBox(height: 12),
            Text(
              'You are changing faster than is wise. Slowing down protects your muscle and energy.',
              style: bodyText(12.5, color: kBodyRed, height: 1.45),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: BodyButton(label: 'Log weight', icon: Icons.add_rounded, onPressed: onLogWeight)),
              const SizedBox(width: 10),
              Expanded(
                child: BodyButton(label: 'Edit goal', filled: false, onPressed: onSetGoal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _eta() {
    final w = progress.projectedWeeks;
    if (w == null) return '–';
    if (w == 0) return 'Reached';
    final weeks = w.round();
    final date = progress.projectedDate(now);
    return date == null ? '$weeks wk' : '$weeks wk · ${shortDate(date)}';
  }

  static IconData _icon(GoalType t) => switch (t) {
        GoalType.loseWeight => Icons.trending_down_rounded,
        GoalType.gainWeight => Icons.trending_up_rounded,
        GoalType.buildMuscle => Icons.fitness_center_rounded,
        GoalType.maintain => Icons.balance_rounded,
      };
}

class _NoGoal extends StatelessWidget {
  final VoidCallback onSetGoal;
  const _NoGoal({required this.onSetGoal});

  @override
  Widget build(BuildContext context) {
    return BodyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kBodyLime.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.flag_rounded, color: kBodyLime, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Set your goal', style: bodyHeading(17))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Lose weight, gain weight or build muscle. Pick a target and the muscles to '
            'prioritise, and your coach will guide your training and food around it.',
            style: bodyText(13, color: kBodyMuted, height: 1.5),
          ),
          const SizedBox(height: 16),
          BodyButton(label: 'Set a goal', icon: Icons.arrow_forward_rounded, onPressed: onSetGoal),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final Color color;
  const _Bar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: kBodyUntrained,
        color: color,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBodyBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: bodyText(10.5, color: kBodySoft)),
            const SizedBox(height: 3),
            Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bodyText(12.5, weight: FontWeight.w700, height: 1.25)),
          ],
        ),
      ),
    );
  }
}
