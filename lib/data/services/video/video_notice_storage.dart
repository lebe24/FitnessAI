import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Remembers which one-time notices the video feature has already shown.
class VideoNoticeStorage {
  static const _boxName = 'app_settings';
  static const _tipsKey = 'video_recording_tips_seen';
  static const _consentKey = 'form_analysis_notice_accepted';

  static Future<bool> _flag(String key) async {
    try {
      final box = await Hive.openBox(_boxName);
      return box.get(key) == true;
    } catch (e) {
      debugPrint('VideoNoticeStorage: read failed — $e');
      return false;
    }
  }

  static Future<void> _set(String key) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(key, true);
      await box.flush();
    } catch (e) {
      // Worst case the notice shows again, which beats failing the action.
      debugPrint('VideoNoticeStorage: write failed — $e');
    }
  }

  /// The "how to film" guide, shown before the first recording.
  static Future<bool> tipsSeen() => _flag(_tipsKey);
  static Future<void> markTipsSeen() => _set(_tipsKey);

  /// The notice before the first analysis: frames (not the video) are sent to
  /// an AI provider, and bystanders can be in the shot.
  static Future<bool> analysisNoticeAccepted() => _flag(_consentKey);
  static Future<void> markAnalysisNoticeAccepted() => _set(_consentKey);
}
