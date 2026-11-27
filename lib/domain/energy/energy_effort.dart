/// How hard a lifting session was, with the activity-intensity (MET) band used
/// for each level. The bands come from the 2024 Compendium (3.5 for general
/// resistance training, 5.0 for squats and deadlifts, 6.0 vigorous; 3.0 is the
/// floor of moderate activity). *Which* band a session falls in is BeFit's own
/// rule, from how often sets were done and how much of the work was big leg lifts.
enum EffortLevel {
  light(3.0, 3.5, 'Light'),
  moderate(3.5, 5.0, 'Moderate'),
  hard(5.0, 6.0, 'Hard');

  const EffortLevel(this.lowMet, this.highMet, this.label);

  final double lowMet;
  final double highMet;
  final String label;
}

class EffortRating {
  final EffortLevel level;

  /// Why, in words the bot can repeat.
  final String reason;

  const EffortRating(this.level, this.reason);

  /// Sets per minute under which there was plenty of rest.
  static const _lightBelow = 0.2;

  /// Sets per minute from which the pace alone is hard work.
  static const _hardFrom = 0.5;

  /// A slightly slower pace still counts as hard when half the sets or more
  /// were big leg lifts.
  static const _hardWithBigLifts = 0.4;

  static final RegExp _bigLift = RegExp(
    r'squat|deadlift|\brdl\b|lunge|leg press|hip thrust|\bclean\b|snatch|thruster',
    caseSensitive: false,
  );

  static bool isBigLift(String exerciseName) => _bigLift.hasMatch(exerciseName);

  factory EffortRating.of({required int sets, required int minutes, int bigLiftSets = 0}) {
    if (sets <= 0 || minutes <= 0) {
      return const EffortRating(
          EffortLevel.moderate, 'No sets were logged, so I assumed a moderate effort.');
    }
    final pace = sets / minutes;
    final every = (1 / pace).round();
    final often = every <= 1 ? 'about one set a minute' : 'about one set every $every minutes';

    if (pace < _lightBelow) {
      return EffortRating(EffortLevel.light, 'You did $often, so there was plenty of rest.');
    }
    final mostlyBig = bigLiftSets * 2 >= sets;
    if (pace >= _hardFrom || (pace >= _hardWithBigLifts && mostlyBig)) {
      return EffortRating(EffortLevel.hard,
          'A quick pace: $often${mostlyBig ? ', much of it big leg lifts' : ''}.');
    }
    return EffortRating(EffortLevel.moderate, 'A steady pace: $often.');
  }
}
