import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/ui/features/onboarding/views/onboarding_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// The single body weight the app kept before there was a log: a value saved
/// from the Analytics screen, or failing that the weight typed in onboarding.
/// Read in kilograms, to start the log from.
class LegacyWeight {
  LegacyWeight._();

  static Future<double?> readKg() async {
    try {
      final box = await Hive.openBox('onboarding_data');
      final saved = box.get('logged_body_weight');
      if (saved is num) {
        final unit = (box.get('logged_body_weight_unit') as String?) ?? 'kg';
        return _toKg(saved.toDouble(), unit);
      }
      final data = await OnboardingStorage.loadOnboardingData();
      final raw = data?.weight?.trim();
      if (raw == null || raw.isEmpty) return null;
      final parts = raw.split(' '); // "75 kg" or "165 lbs"
      final value = double.tryParse(parts.first);
      if (value == null) return null;
      return _toKg(value, parts.length > 1 ? parts.last : 'kg');
    } catch (_) {
      return null;
    }
  }

  static double _toKg(double value, String unit) =>
      unit.toLowerCase().startsWith('lb') ? BodyUnits.lbToKg(value) : value;
}
