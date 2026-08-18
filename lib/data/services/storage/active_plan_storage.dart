import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Remembers which saved program the user is currently training on.
///
/// Before this existed, the "active" plan was whichever one Hive happened to
/// return first from `getAllFitnessPlans()`. That order is box key order — not
/// newest-first, not chosen — so which program drove the home calendar was
/// effectively arbitrary, and generating a new plan did not reliably switch to
/// it.
///
/// Storing the id makes the choice explicit and survives restarts. It is only
/// a pointer: deleting the plan it names is harmless, because the view model
/// falls back to the newest plan when the id no longer resolves.
class ActivePlanStorage {
  static const String _boxName = 'app_settings';
  static const String _key = 'active_plan_id';

  static Future<String?> load() async {
    try {
      final box = await Hive.openBox(_boxName);
      final value = box.get(_key);
      return value is String && value.isNotEmpty ? value : null;
    } catch (e) {
      debugPrint('ActivePlanStorage: load failed — $e');
      return null;
    }
  }

  static Future<void> save(String planId) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_key, planId);
      await box.flush();
    } catch (e) {
      debugPrint('ActivePlanStorage: save failed — $e');
    }
  }

  /// Called when the active plan is deleted, so a stale pointer does not
  /// outlive the thing it points at.
  static Future<void> clear() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.delete(_key);
      await box.flush();
    } catch (e) {
      debugPrint('ActivePlanStorage: clear failed — $e');
    }
  }
}
