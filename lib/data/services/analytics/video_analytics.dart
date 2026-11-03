import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_events.dart';
import 'package:fitness/domain/models/exercise_video.dart';

/// Events for the workout video log and the form analysis.
///
/// Sent: how a video was added, how long it is, the rating, the camera view and
/// confidence, and why an analysis failed. **Never sent:** the exercise name
/// (users can add their own, and it is free text), the muscle the video was
/// filed under, or any sentence the AI wrote. The video itself never leaves the
/// device.
abstract final class VideoAnalytics {
  static void added({required String source, required Duration duration}) =>
      Analytics.track(AnalyticsEvents.exerciseVideoAdded, {
        'source': source,
        'duration_s': duration.inSeconds,
      });

  static void played() => Analytics.track(AnalyticsEvents.exerciseVideoPlayed);

  static void deleted({required bool analysed}) =>
      Analytics.track(AnalyticsEvents.exerciseVideoDeleted, {'analysed': analysed});

  static void analysisStarted({required int frameCount}) =>
      Analytics.track(AnalyticsEvents.formAnalysisStarted, {'frame_count': frameCount});

  static void analysisCompleted(FormAnalysis a, {required Duration took}) =>
      Analytics.track(AnalyticsEvents.formAnalysisCompleted, {
        'overall_score': a.overallScore,
        'confidence': a.confidence.name,
        'camera_view': a.cameraView.name,
        'duration_ms': took.inMilliseconds,
      });

  static void analysisFailed(String reason) =>
      Analytics.track(AnalyticsEvents.formAnalysisFailed, {'reason': reason});

  static void resultViewed(FormAnalysis a) =>
      Analytics.track(AnalyticsEvents.formAnalysisResultViewed, {'overall_score': a.overallScore});

  static void muscleVideosOpened(String muscle) =>
      Analytics.track(AnalyticsEvents.muscleVideosOpened, {'muscle': muscle});
}
