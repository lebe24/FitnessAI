import 'package:hive_flutter/hive_flutter.dart';

/// Persists the user's chosen app language across sessions.
class LocaleStorage {
  static const String _boxName = 'app_settings';
  static const String _localeKey = 'locale_code';

  static Future<Box> get _boxInstance async => Hive.openBox(_boxName);

  static Future<void> saveLocaleCode(String languageCode) async {
    final box = await _boxInstance;
    await box.put(_localeKey, languageCode);
  }

  /// Returns the saved language code (e.g. "en", "es"), or null if unset —
  /// callers should fall back to the device locale in that case.
  static Future<String?> loadLocaleCode() async {
    final box = await _boxInstance;
    return box.get(_localeKey) as String?;
  }
}
