import 'package:hive_flutter/hive_flutter.dart';

/// Whether the user has allowed usage analytics.
///
/// On by default, with a switch in Settings that turns it off for good: this is
/// the "clear information and an easy opt-out" model. It is stored on the
/// device next to the other app settings, and is applied before the SDK is
/// started so an opted-out user never sends a single event.
class AnalyticsPreferences {
  static const String _boxName = 'app_settings';
  static const String _key = 'analytics_enabled';

  static Future<Box> get _box async => Hive.openBox(_boxName);

  static Future<bool> isEnabled() async {
    final box = await _box;
    return (box.get(_key) as bool?) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final box = await _box;
    await box.put(_key, enabled);
  }
}
