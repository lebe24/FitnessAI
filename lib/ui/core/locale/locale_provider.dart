import 'package:fitness/data/services/storage/locale_storage.dart';
import 'package:flutter/material.dart';

/// Supported app languages. Add an entry here + an `app_<code>.arb` file
/// (see lib/l10n/) + a [LocaleProvider.supportedLocales] update to add a
/// new language.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('es'),
];

/// Holds the user's chosen UI language and persists it across app restarts.
/// Provided once at the root of the app (see main.dart) so changing the
/// locale rebuilds the whole `MaterialApp.router` subtree.
class LocaleProvider extends ChangeNotifier {
  Locale? _locale; // null == follow system locale

  Locale? get locale => _locale;

  /// Loads the previously saved language choice, if any. Call once at
  /// startup before the first frame that needs translations.
  Future<void> loadSaved() async {
    final code = await LocaleStorage.loadLocaleCode();
    if (code != null) {
      _locale = kSupportedLocales.firstWhere(
        (l) => l.languageCode == code,
        orElse: () => kSupportedLocales.first,
      );
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale?.languageCode == locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    await LocaleStorage.saveLocaleCode(locale.languageCode);
  }
}
