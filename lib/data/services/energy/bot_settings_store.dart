import 'package:fitness/domain/energy/bot_settings.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// The bot's name and look. Kept on the phone.
abstract class BotSettingsStore {
  Future<BotSettings> load();
  Future<void> save(BotSettings settings);
}

class HiveBotSettingsStore implements BotSettingsStore {
  static const _box = 'app_settings';
  static const _name = 'energy_bot_name';
  static const _mascot = 'energy_bot_mascot';

  @override
  Future<BotSettings> load() async {
    try {
      final box = await Hive.openBox(_box);
      final name = box.get(_name);
      return BotSettings(
        name: name is String ? BotSettings.cleanName(name) : BotSettings.defaultName,
        mascot: BotMascot.values.asNameMap()[box.get(_mascot)] ?? BotMascot.flame,
      );
    } catch (_) {
      return const BotSettings();
    }
  }

  @override
  Future<void> save(BotSettings settings) async {
    final box = await Hive.openBox(_box);
    await box.putAll({_name: settings.name, _mascot: settings.mascot.name});
  }
}

/// Kept in memory, for tests and previews.
class MemoryBotSettingsStore implements BotSettingsStore {
  BotSettings saved;
  MemoryBotSettingsStore([this.saved = const BotSettings()]);

  @override
  Future<BotSettings> load() async => saved;

  @override
  Future<void> save(BotSettings settings) async => saved = settings;
}
