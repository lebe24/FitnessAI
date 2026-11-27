import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_events.dart';

/// Events for the workout history and the workout videos page.
///
/// Counts and yes/no flags only. **Never sent:** a workout name, an exercise
/// name, a weight, a date, or anything the coach wrote about a session.
abstract final class HistoryAnalytics {
  static void opened({required int sessions, required int months}) =>
      Analytics.track(AnalyticsEvents.workoutHistoryOpened, {'sessions': sessions, 'months': months});

  static void monthSelected({required bool all}) =>
      Analytics.track(AnalyticsEvents.workoutHistoryMonthSelected, {'all': all});

  static void sessionOpened({required int exercises, required bool hasFeedback}) =>
      Analytics.track(AnalyticsEvents.workoutSessionOpened, {'exercises': exercises, 'has_feedback': hasFeedback});

  static void shareOpened({required int bests}) =>
      Analytics.track(AnalyticsEvents.sessionShareOpened, {'bests': bests});

  static void shareFinished({required String format, required String outcome}) =>
      Analytics.track(AnalyticsEvents.sessionShareFinished, {'format': format, 'outcome': outcome});

  static void shareFailed({required String format}) =>
      Analytics.track(AnalyticsEvents.sessionShareFailed, {'format': format});

  static void videosOpened({required int count, required int analysed}) =>
      Analytics.track(AnalyticsEvents.workoutVideosOpened, {'count': count, 'analysed': analysed});

  static void videosDeletedAll({required int count}) =>
      Analytics.track(AnalyticsEvents.workoutVideosDeletedAll, {'count': count});
}
