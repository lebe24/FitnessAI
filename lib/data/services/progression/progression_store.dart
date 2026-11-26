import 'dart:convert';

import 'package:fitness/data/models/home/workout_plan_model.dart';
import 'package:fitness/domain/progression/progression_proposal.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Where smart-update settings and the applied-update log are kept.
abstract class ProgressionStore {
  Future<ProgressionSettings> loadSettings();
  Future<void> saveSettings(ProgressionSettings settings);

  /// When the plan's history was last looked at and acted on, by applying or
  /// by choosing "not this time".
  Future<DateTime?> lastChecked(String planId);
  Future<void> markChecked(String planId, DateTime at);

  /// Updates applied to [planId], newest first.
  Future<List<AppliedUpdate>> updates(String planId);
  Future<void> saveUpdates(String planId, List<AppliedUpdate> updates);
}

/// Hive-backed store. Everything is small JSON, so one box is enough.
class HiveProgressionStore implements ProgressionStore {
  static const _boxName = 'progression';

  Future<Box> _box() => Hive.openBox(_boxName);

  @override
  Future<ProgressionSettings> loadSettings() async {
    try {
      final raw = (await _box()).get('settings');
      if (raw is! String) return const ProgressionSettings();
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return ProgressionSettings(
        enabled: j['enabled'] as bool? ?? true,
        mode: _byName(ApplyMode.values, j['mode'], ApplyMode.review),
        cadence: _byName(ProgressionCadence.values, j['cadence'], ProgressionCadence.weekly),
        pace: _byName(ProgressionPace.values, j['pace'], ProgressionPace.balanced),
        deloads: j['deloads'] as bool? ?? true,
      );
    } catch (e) {
      debugPrint('ProgressionStore: settings unreadable — $e');
      return const ProgressionSettings();
    }
  }

  @override
  Future<void> saveSettings(ProgressionSettings s) async {
    final box = await _box();
    await box.put(
      'settings',
      jsonEncode({
        'enabled': s.enabled,
        'mode': s.mode.name,
        'cadence': s.cadence.name,
        'pace': s.pace.name,
        'deloads': s.deloads,
      }),
    );
    await box.flush();
  }

  @override
  Future<DateTime?> lastChecked(String planId) async {
    final v = (await _box()).get('checked_$planId');
    return v is String ? DateTime.tryParse(v) : null;
  }

  @override
  Future<void> markChecked(String planId, DateTime at) async {
    final box = await _box();
    await box.put('checked_$planId', at.toIso8601String());
    await box.flush();
  }

  @override
  Future<List<AppliedUpdate>> updates(String planId) async {
    try {
      final raw = (await _box()).get('updates_$planId');
      if (raw is! String) return [];
      return [
        for (final j in jsonDecode(raw) as List) _fromJson(Map<String, dynamic>.from(j as Map))
      ];
    } catch (e) {
      debugPrint('ProgressionStore: update log unreadable — $e');
      return [];
    }
  }

  @override
  Future<void> saveUpdates(String planId, List<AppliedUpdate> updates) async {
    final box = await _box();
    await box.put('updates_$planId', jsonEncode([for (final u in updates) _toJson(u)]));
    await box.flush();
  }

  static Map<String, dynamic> _toJson(AppliedUpdate u) => {
        'version': u.version,
        'date': u.date.toIso8601String(),
        'changeCount': u.changeCount,
        'highlights': u.highlights,
        'auto': u.wasAutomatic,
        'deload': u.isDeload,
        if (u.previous != null) 'previous': WeeklySplitModel.fromSplit(u.previous!).toJson(),
      };

  static AppliedUpdate _fromJson(Map<String, dynamic> j) => AppliedUpdate(
        version: j['version'] as int,
        date: DateTime.parse(j['date'] as String),
        changeCount: j['changeCount'] as int,
        highlights: [for (final h in (j['highlights'] as List? ?? const [])) h.toString()],
        wasAutomatic: j['auto'] as bool? ?? false,
        isDeload: j['deload'] as bool? ?? false,
        previous: j['previous'] is Map
            ? WeeklySplitModel.fromJson(Map<String, dynamic>.from(j['previous'] as Map))
            : null,
      );

  static T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}
