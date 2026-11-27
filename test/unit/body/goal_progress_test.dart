import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/goal_progress.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 25, 9);

List<BodyWeightEntry> _w(List<(int, double)> pairs) => [
      for (final (daysAgo, kg) in pairs)
        BodyWeightEntry(date: DateTime(2026, 11, 25).subtract(Duration(days: daysAgo)), weightKg: kg)
    ];

void main() {
  group('weight trend', () {
    test('the weekly slope of a steady loss', () {
      final t = GoalMath.trend(_w([(21, 82), (14, 81), (7, 80), (0, 79)]), _now);
      expect(t.currentKg, 79);
      expect(t.weeklyKg, -1.0);
    });

    test('needs three weigh-ins', () {
      final t = GoalMath.trend(_w([(7, 80), (0, 79)]), _now);
      expect(t.weeklyKg, isNull);
      expect(t.currentKg, 79);
    });

    test('needs them to span a week', () {
      expect(GoalMath.trend(_w([(4, 80), (2, 79.8), (0, 79.5)]), _now).weeklyKg, isNull);
    });

    test('ignores weigh-ins older than the window', () {
      expect(GoalMath.trend(_w([(90, 95), (80, 94), (0, 80)]), _now).weeklyKg, isNull);
    });

    test('is empty with no weigh-ins', () {
      expect(GoalMath.trend(const [], _now).currentKg, isNull);
    });

    test('a second weigh-in on one day is one entry per day in the log, not here', () {
      // The repository collapses a day to one entry; the maths just takes what it is given.
      expect(GoalMath.trend(_w([(7, 80), (0, 79), (0, 79)]), _now).points, 3);
    });
  });

  group('status', () {
    ProgressStatus s(GoalType type, double weekly, double? planned, {double current = 80}) =>
        GoalMath.status(type, WeightTrend(currentKg: current, weeklyKg: weekly, points: 5, spanDays: 20), planned);

    test('losing weight', () {
      expect(s(GoalType.loseWeight, -0.5, 0.5), ProgressStatus.onTrack);
      expect(s(GoalType.loseWeight, -0.2, 0.5), ProgressStatus.behind);
      expect(s(GoalType.loseWeight, 0.3, 0.5), ProgressStatus.behind);
      expect(s(GoalType.loseWeight, -0.65, 0.5), ProgressStatus.ahead);
      expect(s(GoalType.loseWeight, -1.2, 0.5), ProgressStatus.tooFast);
    });

    test('gaining and maintaining', () {
      expect(s(GoalType.gainWeight, 0.25, 0.25), ProgressStatus.onTrack);
      expect(s(GoalType.maintain, 0.1, 0), ProgressStatus.onTrack);
      expect(s(GoalType.maintain, 0.6, 0), ProgressStatus.behind);
    });

    test('too little data', () {
      expect(GoalMath.status(GoalType.loseWeight, const WeightTrend(currentKg: 80, points: 1), 0.5),
          ProgressStatus.notEnoughData);
    });
  });

  group('projection and calories', () {
    test('weeks to the target at the observed pace', () {
      expect(GoalMath.projectedWeeks(GoalType.loseWeight, 80, 75, -0.5), 10.0);
      expect(GoalMath.projectedWeeks(GoalType.loseWeight, 80, 75, 0.2), isNull);
      expect(GoalMath.projectedWeeks(GoalType.loseWeight, 74, 75, -0.5), 0.0);
      expect(GoalMath.projectedWeeks(GoalType.maintain, 80, 80, 0), isNull);
    });

    test('calories match the rate', () {
      expect(GoalMath.calorieAdjustment(GoalType.loseWeight, 0.5), -550);
      expect(GoalMath.calorieAdjustment(GoalType.gainWeight, 0.25), 275);
      expect(GoalMath.calorieAdjustment(GoalType.buildMuscle, 0.2), 250);
      expect(GoalMath.calorieAdjustment(GoalType.maintain, null), 0);
    });

    test('percent complete', () {
      expect(GoalMath.percentComplete(GoalType.loseWeight, 90, 85, 80), 50);
      expect(GoalMath.percentComplete(GoalType.loseWeight, 90, 95, 80), 0);
      expect(GoalMath.percentComplete(GoalType.loseWeight, 90, 70, 80), 100);
      expect(GoalMath.percentComplete(GoalType.buildMuscle, null, 80, null), isNull);
    });

    test('the safe weekly rate is one percent of body weight', () {
      expect(GoalMath.maxWeeklyRateKg(80), 0.8);
    });

    test('the default planned rate follows the goal', () {
      expect(GoalMath.plannedRateKg(GoalType.loseWeight, 80, null), 0.4);
      expect(GoalMath.plannedRateKg(GoalType.loseWeight, 80, 0.6), 0.6);
      expect(GoalMath.plannedRateKg(GoalType.maintain, 80, null), 0.0);
    });
  });

  group('GoalProgress', () {
    test('is no goal without one', () {
      expect(GoalProgress.of(null, const [], _now).status, ProgressStatus.noGoal);
    });

    test('brings the pieces together', () {
      final p = GoalProgress.of(
        const FitnessGoal(
            type: GoalType.loseWeight, startWeightKg: 82, targetWeightKg: 76, weeklyRateKg: 0.5),
        _w([(21, 82), (14, 81.5), (7, 81), (0, 80.5)]),
        _now,
      );
      expect(p.status, ProgressStatus.onTrack);
      expect(p.percentComplete, 25);
      expect(p.projectedWeeks, 9.0);
      expect(p.calorieAdjustment, -550);
      expect(p.projectedDate(_now), DateTime(2026, 11, 25).add(const Duration(days: 63)));
    });
  });

  group('units', () {
    test('convert and format', () {
      expect(BodyUnits.weight(80, imperial: false), '80 kg');
      expect(BodyUnits.weight(80.5, imperial: false), '80.5 kg');
      expect(BodyUnits.weight(80, imperial: true), '176.4 lb');
      expect(BodyUnits.length(100, imperial: true), '39.4 in');
      expect(BodyUnits.lbToKg(BodyUnits.kgToLb(72.3)), closeTo(72.3, 1e-9));
    });
  });

  group('muscle groups', () {
    test('every body-map slug belongs to at most one group', () {
      final seen = <String>{};
      for (final g in MuscleGroup.values) {
        for (final s in g.slugs) {
          expect(seen.add(s), isTrue, reason: '$s is in two groups');
        }
      }
    });

    test('slugs resolve to groups', () {
      expect(MuscleGroup.forSlug('quadriceps'), MuscleGroup.quads);
      expect(MuscleGroup.forSlug('upper-back'), MuscleGroup.back);
      expect(MuscleGroup.forSlug('tibialis'), isNull);
    });
  });
}
