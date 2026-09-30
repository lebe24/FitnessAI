import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Remembers that the "your trial is ending" notice has been shown.
///
/// Keyed by the trial's end date rather than a bare boolean, so a user who
/// trials, lapses and trials again later is reminded each time — while the
/// same trial never nags twice. A reminder that reappears on every launch
/// reads as a dark pattern, which is the opposite of the point.
class TrialReminderStorage {
  static const String _boxName = 'app_settings';
  static const String _key = 'trial_reminder_shown_for';

  /// Two readings of the same trial's end can differ by a few seconds between
  /// entitlement refreshes. Anything inside this window is the same trial.
  static const Duration _sameTrial = Duration(hours: 12);

  static Future<DateTime?> lastRemindedFor() async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(_key);
      return raw is String ? DateTime.tryParse(raw) : null;
    } catch (e) {
      debugPrint('TrialReminderStorage: read failed — $e');
      return null;
    }
  }

  static Future<void> markShown(DateTime endsAt) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_key, endsAt.toIso8601String());
      await box.flush();
    } catch (e) {
      // Worst case the user sees the notice twice, which beats crashing on
      // the home screen.
      debugPrint('TrialReminderStorage: write failed — $e');
    }
  }

  /// Whether to show the notice now.
  ///
  /// [willRenew] is the one that surprises people: someone who has already
  /// cancelled still has an active trial and still sees [trialEndingSoon], but
  /// telling them they are about to be charged would simply be false.
  static bool shouldRemind({
    required bool trialEndingSoon,
    required bool willRenew,
    required DateTime? endsAt,
    required DateTime? lastRemindedFor,
  }) {
    if (!trialEndingSoon || !willRenew || endsAt == null) return false;
    if (lastRemindedFor == null) return true;
    return lastRemindedFor.difference(endsAt).abs() >= _sameTrial;
  }
}
