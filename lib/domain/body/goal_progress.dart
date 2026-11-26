import 'package:fitness/domain/body/body_models.dart';

/// The latest weight and the weekly slope over the recent weigh-ins.
class WeightTrend {
  final double? currentKg;

  /// Kilograms per week from a straight line through the last 28 days.
  /// Null until there are at least three weigh-ins spanning a week.
  final double? weeklyKg;
  final int points;
  final int spanDays;

  const WeightTrend({this.currentKg, this.weeklyKg, this.points = 0, this.spanDays = 0});
}

enum ProgressStatus { noGoal, notEnoughData, behind, onTrack, ahead, tooFast }

/// The goal maths: pace, status, projection, calories.
///
/// The same rules as the backend's `goal_metrics.py`, so the screen and the AI
/// advice describe one set of numbers. Pure, so it works offline.
class GoalMath {
  GoalMath._();

  /// Faster than this fraction of body weight per week is flagged.
  static const safeFraction = 0.01;
  static const _kcalPerKg = 7700;
  static const _defaultRate = {
    GoalType.loseWeight: 0.005,
    GoalType.gainWeight: 0.0025,
    GoalType.buildMuscle: 0.0025,
    GoalType.maintain: 0.0,
  };

  static double maxWeeklyRateKg(double weightKg) =>
      (weightKg * safeFraction * 100).round() / 100;

  static WeightTrend trend(List<BodyWeightEntry> entries, DateTime now, {int windowDays = 28}) {
    if (entries.isEmpty) return const WeightTrend();
    final today = DateTime(now.year, now.month, now.day);
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final current = sorted.last.weightKg;
    final recent = [
      for (final e in sorted)
        if (today.difference(e.date).inDays <= windowDays) e
    ];
    if (recent.length < 3) return WeightTrend(currentKg: current, points: recent.length);

    final span = recent.last.date.difference(recent.first.date).inDays;
    if (span < 7) return WeightTrend(currentKg: current, points: recent.length, spanDays: span);

    final xs = [for (final e in recent) e.date.difference(recent.first.date).inDays.toDouble()];
    final ys = [for (final e in recent) e.weightKg];
    final n = xs.length;
    final meanX = xs.reduce((a, b) => a + b) / n;
    final meanY = ys.reduce((a, b) => a + b) / n;
    var num = 0.0, den = 0.0;
    for (var i = 0; i < n; i++) {
      num += (xs[i] - meanX) * (ys[i] - meanY);
      den += (xs[i] - meanX) * (xs[i] - meanX);
    }
    final slope = den == 0 ? 0.0 : num / den;
    return WeightTrend(
      currentKg: current,
      weeklyKg: (slope * 7 * 100).round() / 100,
      points: n,
      spanDays: span,
    );
  }

  /// The weekly change being aimed for, always positive.
  static double? plannedRateKg(GoalType type, double? weightKg, double? chosen) {
    if (chosen != null) return chosen;
    if (weightKg == null) return null;
    return ((weightKg * (_defaultRate[type] ?? 0)) * 100).round() / 100;
  }

  static ProgressStatus status(GoalType type, WeightTrend trend, double? planned) {
    final weekly = trend.weeklyKg;
    final current = trend.currentKg;
    if (weekly == null || current == null) return ProgressStatus.notEnoughData;

    final d = type.direction;
    if (d == 0) {
      return weekly.abs() <= current * 0.0025 ? ProgressStatus.onTrack : ProgressStatus.behind;
    }
    final signed = weekly * d;
    final limit = current * safeFraction;
    if (signed > limit && signed > (planned ?? 0) * 1.5) return ProgressStatus.tooFast;
    if (signed <= 0) return ProgressStatus.behind;
    if (planned == null || planned == 0) return ProgressStatus.onTrack;
    final ratio = signed / planned;
    if (ratio < 0.75) return ProgressStatus.behind;
    if (ratio <= 1.25) return ProgressStatus.onTrack;
    return ratio <= 1.5 ? ProgressStatus.ahead : ProgressStatus.tooFast;
  }

  /// Weeks to the target at the observed pace; 0 if already there; null when
  /// the weight is not heading that way.
  static double? projectedWeeks(GoalType type, double? current, double? target, double? weeklyKg) {
    final d = type.direction;
    if (d == 0 || current == null || target == null) return null;
    final remaining = (target - current) * d;
    if (remaining <= 0) return 0;
    if (weeklyKg == null || weeklyKg * d <= 0) return null;
    return (remaining / (weeklyKg * d) * 10).round() / 10;
  }

  /// Daily kcal above (+) or below (−) maintenance that matches the planned rate.
  static int? calorieAdjustment(GoalType type, double? planned) {
    final d = type.direction;
    if (d == 0) return 0;
    if (type == GoalType.buildMuscle) return 250;
    if (planned == null) return null;
    final kcal = planned * _kcalPerKg / 7;
    return ((kcal / 25).round() * 25) * d;
  }

  /// How far from the start toward the target the weight has moved, 0–100.
  static int? percentComplete(GoalType type, double? start, double? current, double? target) {
    if (type.direction == 0 || start == null || current == null || target == null || start == target) {
      return null;
    }
    final done = (current - start) / (target - start);
    return (done * 100).round().clamp(0, 100);
  }
}

/// Everything the goal card shows, worked out from the goal and the weigh-ins.
class GoalProgress {
  final FitnessGoal? goal;
  final WeightTrend trend;
  final ProgressStatus status;
  final double? plannedRateKg;
  final double? projectedWeeks;
  final int? percentComplete;
  final int? calorieAdjustment;

  const GoalProgress({
    required this.goal,
    required this.trend,
    required this.status,
    this.plannedRateKg,
    this.projectedWeeks,
    this.percentComplete,
    this.calorieAdjustment,
  });

  factory GoalProgress.of(FitnessGoal? goal, List<BodyWeightEntry> entries, DateTime now) {
    final trend = GoalMath.trend(entries, now);
    if (goal == null) {
      return GoalProgress(goal: null, trend: trend, status: ProgressStatus.noGoal);
    }
    final planned = GoalMath.plannedRateKg(goal.type, trend.currentKg, goal.weeklyRateKg);
    return GoalProgress(
      goal: goal,
      trend: trend,
      status: GoalMath.status(goal.type, trend, planned),
      plannedRateKg: planned,
      projectedWeeks: GoalMath.projectedWeeks(
          goal.type, trend.currentKg, goal.targetWeightKg, trend.weeklyKg),
      percentComplete: GoalMath.percentComplete(
          goal.type, goal.startWeightKg, trend.currentKg, goal.targetWeightKg),
      calorieAdjustment: GoalMath.calorieAdjustment(goal.type, planned),
    );
  }

  DateTime? projectedDate(DateTime now) {
    final w = projectedWeeks;
    if (w == null) return null;
    return DateTime(now.year, now.month, now.day).add(Duration(days: (w * 7).round()));
  }
}
