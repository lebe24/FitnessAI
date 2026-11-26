import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_events.dart';
import 'package:fitness/domain/body/body_advice.dart';
import 'package:fitness/domain/body/body_models.dart';

/// Events for the Stats tab's goal, weight, measurements and muscle focus.
///
/// Sent: that a goal was set and of what type, whether it has a target and a
/// date, how many muscles are pinned, how a weight was logged, how many sites
/// were measured, and how the advice request went. **Never sent:** a weight, a
/// measurement, a target, a date, a note, or anything the advice said. Body data
/// is health data; the events only say what the person did.
abstract final class BodyAnalytics {
  static void cardTapped({required String card, required bool locked}) =>
      Analytics.track(AnalyticsEvents.analyticsCardTapped, {'card': card, 'locked': locked});

  static void goalSet(FitnessGoal goal, {required bool replaced}) =>
      Analytics.track(AnalyticsEvents.goalSet, {
        'type': goal.type.name,
        'has_target_weight': goal.targetWeightKg != null,
        'has_target_date': goal.targetDate != null,
        'focus_count': goal.focusMuscles.length,
        'replaced': replaced,
      });

  static void goalCleared(GoalType type) =>
      Analytics.track(AnalyticsEvents.goalCleared, {'type': type.name});

  static void weightLogged({
    required String source,
    required bool backdated,
    required bool hasNote,
    required bool offline,
  }) =>
      Analytics.track(AnalyticsEvents.weightLogged, {
        'source': source,
        'backdated': backdated,
        'has_note': hasNote,
        'offline': offline,
      });

  static void measurementsLogged({required int sites}) =>
      Analytics.track(AnalyticsEvents.measurementsLogged, {'sites': sites});

  static void adviceRequested({required bool forced}) =>
      Analytics.track(AnalyticsEvents.goalAdviceRequested, {'forced': forced});

  static void adviceReceived(BodyAdvice advice) => Analytics.track(AnalyticsEvents.goalAdviceReceived, {
        'status': advice.status.name,
        'actions': advice.actions.length,
        'from_model': advice.fromModel,
        'cached': advice.cached,
      });

  static void adviceFailed(BodyTrackingError reason) =>
      Analytics.track(AnalyticsEvents.goalAdviceFailed, {'reason': reason.name});

  static void muscleFocusChanged(MuscleGroup muscle, {required bool focus}) =>
      Analytics.track(AnalyticsEvents.muscleFocusChanged, {'muscle': muscle.name, 'focus': focus});
}
