import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// When the daily motivation lands.
enum MotivationSlot { morning, evening, custom }

/// The user's motivation preferences: tone, delivery slot, and custom time.
class MotivationSchedule {
  final String tone;
  final MotivationSlot slot;
  final int hour;
  final int minute;

  /// Set when messages were last fetched, so we know when to refill.
  final DateTime? lastFetched;

  const MotivationSchedule({
    required this.tone,
    required this.slot,
    required this.hour,
    required this.minute,
    this.lastFetched,
  });

  static const _morningHour = 7;
  static const _eveningHour = 18;

  /// Wall-clock time for a slot; custom keeps whatever the user picked.
  factory MotivationSchedule.forSlot(
    String tone,
    MotivationSlot slot, {
    int? hour,
    int? minute,
  }) {
    switch (slot) {
      case MotivationSlot.morning:
        return MotivationSchedule(
            tone: tone, slot: slot, hour: _morningHour, minute: 0);
      case MotivationSlot.evening:
        return MotivationSchedule(
            tone: tone, slot: slot, hour: _eveningHour, minute: 0);
      case MotivationSlot.custom:
        return MotivationSchedule(
          tone: tone,
          slot: slot,
          hour: hour ?? _morningHour,
          minute: minute ?? 0,
        );
    }
  }

  /// What the backend agent is told about timing — 'morning'/'evening' read as
  /// intent, a custom slot passes the literal time so the copy can match it.
  String get scheduleLabel => switch (slot) {
        MotivationSlot.morning => 'morning',
        MotivationSlot.evening => 'evening',
        MotivationSlot.custom =>
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      };

  String get timeLabel {
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h12:${minute.toString().padLeft(2, '0')} $period';
  }

  Map<String, dynamic> toMap() => {
        'tone': tone,
        'slot': slot.name,
        'hour': hour,
        'minute': minute,
        'lastFetched': lastFetched?.toIso8601String(),
      };

  static MotivationSchedule fromMap(Map m) => MotivationSchedule(
        tone: m['tone'] as String? ?? '',
        slot: MotivationSlot.values.firstWhere(
          (s) => s.name == m['slot'],
          orElse: () => MotivationSlot.morning,
        ),
        hour: (m['hour'] as num?)?.toInt() ?? _morningHour,
        minute: (m['minute'] as num?)?.toInt() ?? 0,
        lastFetched: DateTime.tryParse(m['lastFetched'] as String? ?? ''),
      );
}

/// Persists the motivation schedule so notifications can be re-armed after a
/// device restart or app update.
class MotivationScheduleStorage {
  static const String boxName = 'app_settings';
  static const String _key = 'motivation_schedule';

  static Future<Box> _box() async =>
      Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await Hive.openBox(boxName);

  static Future<void> save(MotivationSchedule schedule) async {
    try {
      final box = await _box();
      await box.put(_key, schedule.toMap());
    } catch (e) {
      debugPrint('MotivationScheduleStorage.save failed: $e');
    }
  }

  static Future<MotivationSchedule?> load() async {
    try {
      final box = await _box();
      final raw = box.get(_key);
      return raw is Map ? MotivationSchedule.fromMap(raw) : null;
    } catch (e) {
      debugPrint('MotivationScheduleStorage.load failed: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final box = await _box();
      await box.delete(_key);
    } catch (e) {
      debugPrint('MotivationScheduleStorage.clear failed: $e');
    }
  }
}
