/// The user's workout streak, derived from their completed sessions.
///
/// This exists because the home badge and the analytics card used to compute
/// the streak from two unrelated sources and disagreed:
///
///   * home read `current_streak` off the active `workout_plan` row, which the
///     backend only rewrites when a session is patched to completed — so it
///     went stale whenever a session was logged any other way, and survived
///     as a stale value indefinitely.
///   * analytics counted distinct dates in the completed-session list.
///
/// Both now build a [WorkoutStreak] from the same session data through the
/// same code path, so the two screens cannot drift apart again.
///
/// [days] is the count of **distinct days on which a workout was completed** —
/// matching what the analytics card has always shown. Note this is a lifetime
/// total, not a run of consecutive days; see [consecutiveDays] for that.
class WorkoutStreak {
  /// Distinct dates, each normalised to midnight so repeated sessions on one
  /// day count once.
  final Set<DateTime> workoutDates;

  const WorkoutStreak(this.workoutDates);

  static const WorkoutStreak empty = WorkoutStreak(<DateTime>{});

  /// Build from the `date_n_duration` rows returned by `getUserData`, i.e.
  /// `[{ 'date_n_duration': [{'date': ISO, 'duration': num}, ...] }]`.
  ///
  /// Anything unparseable is skipped rather than throwing — a single malformed
  /// row must not blank out the whole streak.
  factory WorkoutStreak.fromUserData(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return empty;
    final raw = rows.first['date_n_duration'];
    if (raw is! List) return empty;

    final dates = <DateTime>{};
    for (final entry in raw) {
      if (entry is! Map) continue;
      final value = entry['date'];
      if (value is! String) continue;
      final parsed = DateTime.tryParse(value);
      if (parsed == null) continue;
      dates.add(DateTime(parsed.year, parsed.month, parsed.day));
    }
    return WorkoutStreak(dates);
  }

  /// Distinct days with a completed workout.
  int get days => workoutDates.length;

  /// Longest run of consecutive days ending today or yesterday.
  ///
  /// Yesterday still counts so the streak does not appear to break simply
  /// because today's workout has not happened yet. Not currently displayed —
  /// kept so a true consecutive streak can be shown without recomputing the
  /// date set somewhere else and reintroducing the drift this class fixes.
  int consecutiveDays({DateTime? asOf}) {
    if (workoutDates.isEmpty) return 0;
    final now = asOf ?? DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);

    if (!workoutDates.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!workoutDates.contains(cursor)) return 0;
    }

    var run = 0;
    while (workoutDates.contains(cursor)) {
      run++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return run;
  }
}
