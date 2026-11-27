import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_events.dart';

/// Events for adjusting the plan and for the smart plan updates with the coach.
///
/// Fixed labels, counts and flags only. **Never sent:** a free-text goal
/// (onboarding allows one), height, weight, gender or date of birth, or the
/// coach's wording.
abstract final class PlanAnalytics {
  static const _goals = {'Lose Weight', 'Build Muscle', 'Maintain Gains', 'Build Aesthetics'};
  static const _levels = {'Beginner', 'Experienced', 'Freak of Nature', 'God in Human Form'};

  /// A goal's label if it is one of the four presets, otherwise `custom`: a
  /// goal a person typed can say anything.
  static String goalLabel(String? goal) => goal == null ? 'none' : (_goals.contains(goal) ? goal : 'custom');

  static String levelLabel(String? level) => level == null ? 'none' : (_levels.contains(level) ? level : 'other');

  static void adjustSubmitted({
    required String? goal,
    required String? experience,
    required int days,
    required bool changedGoal,
    required bool changedExperience,
    required bool changedDays,
    required bool heightMetric,
    required bool weightMetric,
  }) =>
      Analytics.track(AnalyticsEvents.planAdjustSubmitted, {
        'goal': goalLabel(goal),
        'experience': levelLabel(experience),
        'days_per_week': days,
        'changed_goal': changedGoal,
        'changed_experience': changedExperience,
        'changed_days': changedDays,
        'height_unit': heightMetric ? 'metric' : 'imperial',
        'weight_unit': weightMetric ? 'metric' : 'imperial',
      });

  /// [reason] is `missing_fields` or `invalid_height`.
  static void adjustBlocked(String reason) =>
      Analytics.track(AnalyticsEvents.planAdjustBlocked, {'reason': reason});

  static void updateProposed({required int changes, required bool deload}) =>
      Analytics.track(AnalyticsEvents.planUpdateProposed, {'changes': changes, 'deload': deload});

  static void updateCoachReviewed({
    required bool reviewed,
    required int approved,
    required int softened,
    required int held,
  }) =>
      Analytics.track(AnalyticsEvents.planUpdateCoachReviewed, {
        'reviewed': reviewed,
        'approved': approved,
        'softened': softened,
        'held': held,
      });

  static void updateApplied({required int changes, required int skipped, required bool automatic}) =>
      Analytics.track(AnalyticsEvents.planUpdateApplied,
          {'changes': changes, 'skipped': skipped, 'automatic': automatic});

  static void updateDismissed() => Analytics.track(AnalyticsEvents.planUpdateDismissed);

  static void updateUndone() => Analytics.track(AnalyticsEvents.planUpdateUndone);
}
