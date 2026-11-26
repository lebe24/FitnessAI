// Sample data for the design-review preview only. The app never reads this.
import 'package:fitness/domain/body/body_advice.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/goal_progress.dart';
import 'package:fitness/domain/body/muscle_focus.dart';
import 'package:fitness/domain/body/scan_summary.dart';

class AnalyticsSamples {
  static final now = DateTime(2026, 11, 25, 9);

  static const goal = FitnessGoal(
    id: 'g',
    type: GoalType.loseWeight,
    startWeightKg: 84,
    targetWeightKg: 76,
    weeklyRateKg: 0.5,
    focusMuscles: [MuscleGroup.quads, MuscleGroup.chest],
  );

  static final weights = [
    for (final (d, kg) in <(int, double)>[
      (56, 84.0), (50, 83.6), (45, 83.4), (38, 82.9), (32, 82.7), (27, 82.1), (21, 81.8),
      (15, 81.4), (10, 81.0), (6, 80.8), (3, 80.6), (0, 80.2),
    ])
      BodyWeightEntry(date: DateTime(2026, 11, 25).subtract(Duration(days: d)), weightKg: kg),
  ];

  static GoalProgress progress = GoalProgress.of(goal, weights, now);

  static final advice = BodyAdvice(
    status: ProgressStatus.onTrack,
    headline: 'You are on track to reach 76 kg',
    summary: 'Your weight is falling at about 0.5 kg a week, right on plan. Your quads and chest '
        'are behind the rest of your training, so that is where to add work.',
    actions: const [
      AdviceAction(
        title: 'Add leg volume',
        detail: 'Quads get about 5 sets a week. Add two sets of leg press and one of lunges to reach 10.',
      ),
      AdviceAction(
        title: 'Keep your calories about 550 below maintenance',
        detail: 'That matches your pace. If the scale stalls for two weeks, trim a little, not a lot.',
      ),
      AdviceAction(
        title: 'Measure your waist monthly',
        detail: 'On a cut the tape shows fat loss and kept muscle that the scale blends together.',
      ),
    ],
    disclaimer: 'This is coaching based on what you have logged, not medical advice. '
        'Check with a doctor before a big change to your diet or training.',
    generatedAt: now,
  );

  static MuscleStatus _m(MuscleGroup g, MuscleLevel l, int score, double sets,
          {double? trend, int? since, bool pinned = false, String? reason}) =>
      MuscleStatus(
        group: g,
        level: l,
        score: score,
        weeklySets: sets,
        targetSets: MuscleFocus.targetSets(g, GoalType.loseWeight),
        strengthTrendPct: trend,
        daysSinceTrained: since,
        pinned: pinned,
        reason: reason ?? '${sets.toStringAsFixed(0)} sets a week against about 9 for keeping muscle while you lose weight.',
      );

  static final muscles = [
    _m(MuscleGroup.chest, MuscleLevel.focus, 5, 5.5, trend: 1.5, since: 3, pinned: true),
    _m(MuscleGroup.back, MuscleLevel.strong, 9, 10, trend: 4.2, since: 2),
    _m(MuscleGroup.shoulders, MuscleLevel.strong, 8, 8.5, trend: 2.1, since: 3),
    _m(MuscleGroup.biceps, MuscleLevel.average, 6, 4, since: 2),
    _m(MuscleGroup.triceps, MuscleLevel.average, 6, 3.5, since: 3),
    _m(MuscleGroup.forearms, MuscleLevel.untrained, 1, 0, reason: 'No sets logged in the last four weeks.'),
    _m(MuscleGroup.abs, MuscleLevel.average, 5, 3, since: 5),
    _m(MuscleGroup.traps, MuscleLevel.untrained, 1, 0, reason: 'No sets logged in the last four weeks.'),
    _m(MuscleGroup.quads, MuscleLevel.focus, 4, 5, trend: -3.4, since: 6, pinned: true),
    _m(MuscleGroup.hamstrings, MuscleLevel.average, 6, 5, since: 6),
    _m(MuscleGroup.glutes, MuscleLevel.strong, 8, 7.5, trend: 3.0, since: 6),
    _m(MuscleGroup.calves, MuscleLevel.focus, 3, 1.5, since: 13),
  ];

  static final scan = ScanSummary(
    scannedAt: DateTime(2026, 11, 20),
    overall: 78,
    aesthetics: 78,
    muscleDevelopment: 84,
    conditioning: 76,
    posture: 71,
    bodyFatPct: 18.5,
    muscleMassPct: 41,
    groupScores: const {},
  );

  static const measurements = <MeasurementSite, ({double latestCm, double? changeCm})>{
    MeasurementSite.chest: (latestCm: 101.5, changeCm: 1.5),
    MeasurementSite.waist: (latestCm: 84.0, changeCm: -3.5),
    MeasurementSite.hips: (latestCm: 98.0, changeCm: -1.0),
    MeasurementSite.bicepL: (latestCm: 36.0, changeCm: 0.5),
    MeasurementSite.thighR: (latestCm: 59.5, changeCm: null),
  };
}
