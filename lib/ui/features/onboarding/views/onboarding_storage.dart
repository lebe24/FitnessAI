import 'package:hive_flutter/hive_flutter.dart';
import 'package:fitness/data/models/onboarding/onboarding_data.dart';

class OnboardingStorage {
  static const String _boxName = 'onboarding_data';
  static const String _dataKey = 'user_onboarding_data';
  static const String _completedKey = 'onboarding_completed';
  static Box? _box;

  static Future<Box> get _boxInstance async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }
    return _box!;
  }

  static Future<void> saveOnboardingData(OnboardingData data) async {
    final box = await _boxInstance;
    await box.put(_dataKey, {
      'workoutDays': data.workoutDays,
      'gender': data.gender,
      'goal': data.goal,
      'height': data.height,
      'weight': data.weight,
      'dob': data.dob,
      'experience': data.experience,
    });
  }

  static Future<OnboardingData?> loadOnboardingData() async {
    try {
      final box = await _boxInstance;
      final data = box.get(_dataKey);
      if (data == null) return null;
      return OnboardingData(
        workoutDays: data['workoutDays'] as int?,
        gender: data['gender'] as String?,
        goal: data['goal'] as String?,
        height: data['height'] as String?,
        weight: data['weight'] as String?,
        dob: data['dob'] as String?,
        experience: data['experience'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasOnboardingData() async {
    final box = await _boxInstance;
    return box.containsKey(_dataKey);
  }

  static Future<void> markCompleted() async {
    final box = await _boxInstance;
    await box.put(_completedKey, true);
  }

  static Future<bool> hasCompletedOnboarding() async {
    final box = await _boxInstance;
    return box.get(_completedKey, defaultValue: false) == true;
  }

  static Future<void> clearOnboardingData() async {
    final box = await _boxInstance;
    await box.delete(_dataKey);
    await box.delete(_completedKey);
  }
}
