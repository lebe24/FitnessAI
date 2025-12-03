import 'package:hive_flutter/hive_flutter.dart';
import 'package:fitness/app/ui/onboarding/model/onboarding_data.dart';

class OnboardingStorage {
  static const String _boxName = 'onboarding_data';
  static const String _key = 'user_onboarding_data';
  static Box<Map>? _box;

  static Future<Box<Map>> get _boxInstance async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<Map>(_boxName);
    }
    return _box!;
  }

  /// Save onboarding data to local storage
  static Future<void> saveOnboardingData(OnboardingData data) async {
    final box = await _boxInstance;
    await box.put(_key, {
      'workoutDays': data.workoutDays,
      'gender': data.gender,
      'goal': data.goal,
      'height': data.height,
      'weight': data.weight,
      'dob': data.dob,
      'experience': data.experience,
    });
  }

  /// Load onboarding data from local storage
  static Future<OnboardingData?> loadOnboardingData() async {
    try {
      final box = await _boxInstance;
      final data = box.get(_key);
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
    } catch (e) {
      return null;
    }
  }

  /// Clear onboarding data
  static Future<void> clearOnboardingData() async {
    final box = await _boxInstance;
    await box.delete(_key);
  }
}


