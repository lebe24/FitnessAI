import 'package:fitness/data/services/energy/bot_settings_store.dart';
import 'package:fitness/domain/energy/bot_settings.dart';
import 'package:flutter/foundation.dart';

/// The bot's name and look, shared so a change in Profile shows everywhere.
class BotSettingsController extends ChangeNotifier {
  final BotSettingsStore _store;
  BotSettings _value = const BotSettings();
  bool _changed = false;
  late final Future<void> loaded;

  BotSettingsController(this._store) {
    loaded = _load();
  }

  BotSettings get value => _value;

  Future<void> _load() async {
    final saved = await _store.load();
    // A change made while loading is newer than what was on disk.
    if (_changed || saved == _value) return;
    _value = saved;
    notifyListeners();
  }

  /// Returns false when it could not be stored.
  Future<bool> save(BotSettings next) async {
    final clean = next.copyWith(name: BotSettings.cleanName(next.name));
    try {
      await _store.save(clean);
    } catch (_) {
      return false;
    }
    _changed = true;
    _value = clean;
    notifyListeners();
    return true;
  }
}
