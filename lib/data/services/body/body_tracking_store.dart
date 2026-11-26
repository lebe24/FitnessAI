import 'dart:convert';

import 'package:fitness/data/models/body/body_json.dart';
import 'package:fitness/domain/body/body_advice.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// The on-device copy of the user's body data, so the screens open instantly
/// and entries made offline are not lost.
abstract class BodyTrackingStore {
  Future<BodySnapshot> load();
  Future<void> save(BodySnapshot snapshot);
  Future<BodyAdvice?> loadAdvice();
  Future<void> saveAdvice(BodyAdvice advice);
  Future<void> clearAdvice();
}

class HiveBodyTrackingStore implements BodyTrackingStore {
  static const _boxName = 'body_tracking';

  Future<Box> _box() => Hive.openBox(_boxName);

  @override
  Future<BodySnapshot> load() async {
    try {
      final raw = (await _box()).get('snapshot');
      if (raw is! String) return BodySnapshot.empty;
      return BodyJson.snapshotFrom(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('BodyTrackingStore: cache unreadable — $e');
      return BodySnapshot.empty;
    }
  }

  @override
  Future<void> save(BodySnapshot snapshot) async {
    final box = await _box();
    await box.put('snapshot', jsonEncode(BodyJson.snapshotTo(snapshot)));
    await box.flush();
  }

  @override
  Future<BodyAdvice?> loadAdvice() async {
    try {
      final raw = (await _box()).get('advice');
      if (raw is! String) return null;
      return BodyJson.adviceFrom(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearAdvice() async {
    final box = await _box();
    await box.delete('advice');
    await box.flush();
  }

  @override
  Future<void> saveAdvice(BodyAdvice advice) async {
    final box = await _box();
    await box.put('advice', jsonEncode(BodyJson.adviceTo(advice)));
    await box.flush();
  }
}
