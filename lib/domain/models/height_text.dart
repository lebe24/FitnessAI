/// Height as the app stores it: a short text, because that is what the plan
/// generator and the profile screen read.
///
/// Different screens have written it differently over time: `1.8 m` and
/// `5 ft 10 in` from onboarding, `178 cm` and `5.9 ft` from the Adjust screen.
/// [toCm] understands all of them, so no screen has to guess.
abstract final class HeightText {
  static const minCm = 50.0;
  static const maxCm = 272.0;

  static final _number = RegExp(r'\d+(?:\.\d+)?');
  static final _meters = RegExp(r'(\d+(?:\.\d+)?)\s*m\b');

  /// Whether [raw] is written in feet and inches.
  static bool isImperial(String? raw) {
    if (raw == null) return false;
    final s = raw.toLowerCase();
    return s.contains('ft') || s.contains("'") || s.contains('’') || RegExp(r'\d\s*in\b').hasMatch(s);
  }

  /// The height in centimetres, or null if [raw] is not a height.
  static double? toCm(String? raw) {
    if (raw == null) return null;
    final s = raw.toLowerCase().trim();
    if (s.isEmpty) return null;
    final nums = [for (final m in _number.allMatches(s)) double.parse(m.group(0)!)];
    if (nums.isEmpty) return null;

    if (s.contains('cm')) return nums.first;
    if (isImperial(s)) {
      if (s.contains('ft') || s.contains("'") || s.contains('’')) {
        final feet = nums.first;
        final inches = nums.length > 1 ? nums[1] : 0.0;
        // `5.9 ft` is decimal feet; `5 ft 10 in` is feet and inches.
        return feet * 30.48 + inches * 2.54;
      }
      return nums.first * 2.54; // inches only
    }
    final meters = _meters.firstMatch(s);
    if (meters != null) return double.parse(meters.group(1)!) * 100;

    // A bare number: centimetres if it is big, metres if it is small.
    final v = nums.first;
    if (v > 100) return v;
    if (v >= 0.5 && v < 3) return v * 100;
    return null;
  }

  /// Whole feet and inches for [cm], with 12 inches carried into a foot.
  static (int feet, int inches) feetInches(double cm) {
    final total = (cm / 2.54).round();
    return (total ~/ 12, total % 12);
  }

  static double fromFeetInches(int feet, int inches) => feet * 30.48 + inches * 2.54;

  /// The way onboarding stores imperial height: `5 ft 10 in`.
  static String storedImperial(int feet, int inches) => '$feet ft $inches in';

  /// `178 cm`, or `178.5 cm` when the person typed a decimal.
  static String storedMetric(double cm) => '${_trim(cm)} cm';

  static String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}
