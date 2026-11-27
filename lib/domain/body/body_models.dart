import 'package:equatable/equatable.dart';

/// What the user is working toward.
enum GoalType {
  loseWeight('lose_weight', 'Lose weight'),
  gainWeight('gain_weight', 'Gain weight'),
  buildMuscle('build_muscle', 'Build muscle'),
  maintain('maintain', 'Maintain');

  const GoalType(this.api, this.label);

  /// The name the backend uses.
  final String api;
  final String label;

  static GoalType fromApi(String? value) =>
      GoalType.values.firstWhere((t) => t.api == value, orElse: () => GoalType.maintain);

  /// Which way the scale should move: -1 down, +1 up, 0 stay.
  int get direction => switch (this) {
        GoalType.loseWeight => -1,
        GoalType.gainWeight || GoalType.buildMuscle => 1,
        GoalType.maintain => 0,
      };

  /// Whether this goal is defined by a target weight.
  bool get needsTarget => this == GoalType.loseWeight || this == GoalType.gainWeight;
}

/// The muscle groups a user can prioritise. They match the backend's list and
/// the groups drawn on the muscle map.
enum MuscleGroup {
  chest('chest', 'Chest', ['chest']),
  back('back', 'Back', ['upper-back', 'lower-back']),
  shoulders('shoulders', 'Shoulders', ['deltoids']),
  biceps('biceps', 'Biceps', ['biceps']),
  triceps('triceps', 'Triceps', ['triceps']),
  forearms('forearms', 'Forearms', ['forearm']),
  abs('abs', 'Abs', ['abs', 'obliques']),
  traps('traps', 'Traps', ['trapezius']),
  quads('quads', 'Quads', ['quadriceps']),
  hamstrings('hamstrings', 'Hamstrings', ['hamstring']),
  glutes('glutes', 'Glutes', ['gluteal']),
  calves('calves', 'Calves', ['calves']);

  const MuscleGroup(this.api, this.label, this.slugs);

  final String api;
  final String label;

  /// The body-map slugs (see `Muscle.all`) this group covers.
  final List<String> slugs;

  /// Big groups get the full weekly-set target; small ones get less because
  /// the big lifts already work them.
  bool get isLarge => const {chest, back, shoulders, quads, hamstrings, glutes}.contains(this);

  static MuscleGroup? fromApi(String? value) {
    for (final g in values) {
      if (g.api == value) return g;
    }
    return null;
  }

  /// The group a body-map slug belongs to, or null for slugs with none.
  static MuscleGroup? forSlug(String slug) {
    for (final g in values) {
      if (g.slugs.contains(slug)) return g;
    }
    return null;
  }
}

class FitnessGoal extends Equatable {
  final String? id;
  final GoalType type;
  final double? startWeightKg;
  final double? targetWeightKg;
  final DateTime? targetDate;

  /// Intended change per week in kilograms, always positive.
  final double? weeklyRateKg;
  final List<MuscleGroup> focusMuscles;
  final DateTime? createdAt;

  const FitnessGoal({
    this.id,
    required this.type,
    this.startWeightKg,
    this.targetWeightKg,
    this.targetDate,
    this.weeklyRateKg,
    this.focusMuscles = const [],
    this.createdAt,
  });

  FitnessGoal copyWith({
    GoalType? type,
    double? startWeightKg,
    double? targetWeightKg,
    DateTime? targetDate,
    double? weeklyRateKg,
    List<MuscleGroup>? focusMuscles,
  }) =>
      FitnessGoal(
        id: id,
        type: type ?? this.type,
        startWeightKg: startWeightKg ?? this.startWeightKg,
        targetWeightKg: targetWeightKg ?? this.targetWeightKg,
        targetDate: targetDate ?? this.targetDate,
        weeklyRateKg: weeklyRateKg ?? this.weeklyRateKg,
        focusMuscles: focusMuscles ?? this.focusMuscles,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, type, startWeightKg, targetWeightKg, targetDate, weeklyRateKg, focusMuscles, createdAt];
}

/// One weigh-in. Weights are kilograms everywhere; conversion is display only.
class BodyWeightEntry extends Equatable {
  final String? id;

  /// The calendar day, with no time of day.
  final DateTime date;
  final double weightKg;
  final String? note;

  BodyWeightEntry({this.id, required DateTime date, required this.weightKg, this.note})
      : date = DateTime(date.year, date.month, date.day);

  @override
  List<Object?> get props => [id, date, weightKg, note];
}

enum MeasurementSite {
  chest('chest', 'Chest'),
  waist('waist', 'Waist'),
  hips('hips', 'Hips'),
  shoulders('shoulders', 'Shoulders'),
  neck('neck', 'Neck'),
  bicepL('bicep_l', 'Left bicep'),
  bicepR('bicep_r', 'Right bicep'),
  forearmL('forearm_l', 'Left forearm'),
  forearmR('forearm_r', 'Right forearm'),
  thighL('thigh_l', 'Left thigh'),
  thighR('thigh_r', 'Right thigh'),
  calfL('calf_l', 'Left calf'),
  calfR('calf_r', 'Right calf');

  const MeasurementSite(this.api, this.label);
  final String api;
  final String label;

  static MeasurementSite? fromApi(String? value) {
    for (final s in values) {
      if (s.api == value) return s;
    }
    return null;
  }
}

/// One tape-measure reading, in centimetres.
class BodyMeasurement extends Equatable {
  final String? id;
  final DateTime date;
  final MeasurementSite site;
  final double valueCm;

  BodyMeasurement({this.id, required DateTime date, required this.site, required this.valueCm})
      : date = DateTime(date.year, date.month, date.day);

  @override
  List<Object?> get props => [id, date, site, valueCm];
}

/// Display units. Storage is always kg and cm.
class BodyUnits {
  BodyUnits._();

  static const kgPerLb = 0.45359237;
  static const cmPerInch = 2.54;

  static double kgToLb(double kg) => kg / kgPerLb;
  static double lbToKg(double lb) => lb * kgPerLb;
  static double cmToIn(double cm) => cm / cmPerInch;
  static double inToCm(double inches) => inches * cmPerInch;

  /// `80.5 kg` or `177.5 lb`, one decimal, no trailing `.0`.
  static String weight(double kg, {required bool imperial}) {
    final v = imperial ? kgToLb(kg) : kg;
    return '${_trim(v)} ${imperial ? 'lb' : 'kg'}';
  }

  static String length(double cm, {required bool imperial}) {
    final v = imperial ? cmToIn(cm) : cm;
    return '${_trim(v)} ${imperial ? 'in' : 'cm'}';
  }

  static String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}
