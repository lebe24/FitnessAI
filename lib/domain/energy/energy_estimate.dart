import 'package:fitness/domain/energy/energy_effort.dart';

/// The estimate in everyday terms.
class EnergyEquivalent {
  /// Plural, e.g. `medium bananas`.
  final String label;
  final int amount;
  const EnergyEquivalent(this.label, this.amount);

  String get words => '$amount ${amount == 1 ? label.replaceFirst(RegExp(r's(?= |$)'), '') : label}';
}

/// Calories for a lifting session, from activity intensity (MET):
/// `kcal = MET × body weight (kg) × hours`. Includes resting energy.
class EnergyEstimate {
  static const _bananaKcal = 105;
  static const _boiledEggKcal = 78;

  /// Level walking at about 3 mph.
  static const _walkingMet = 3.8;

  /// Rounded to the nearest 10: anything finer would claim precision we lack.
  final int lowKcal;
  final int highKcal;
  final double weightKg;
  final int minutes;
  final EffortRating effort;

  const EnergyEstimate._(this.lowKcal, this.highKcal, this.weightKg, this.minutes, this.effort);

  factory EnergyEstimate.of({
    required double weightKg,
    required int minutes,
    EffortRating effort = const EffortRating(EffortLevel.moderate, ''),
  }) {
    int kcal(double met) => (met * weightKg * minutes / 60 / 10).round() * 10;
    return EnergyEstimate._(
        kcal(effort.level.lowMet), kcal(effort.level.highMet), weightKg, minutes, effort);
  }

  int get midKcal => (lowKcal + highKcal) ~/ 2;

  /// Only those that come to at least one.
  List<EnergyEquivalent> get equivalents => [
        for (final e in [
          EnergyEquivalent('medium bananas', (midKcal / _bananaKcal).round()),
          EnergyEquivalent('boiled eggs', (midKcal / _boiledEggKcal).round()),
          EnergyEquivalent('minutes of walking', (midKcal / (_walkingMet * weightKg / 60)).round()),
        ])
          if (e.amount > 0) e
      ];
}
