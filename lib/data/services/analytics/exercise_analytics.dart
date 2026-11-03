import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_events.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/muscle_coverage.dart';
import 'package:fitness/domain/models/workout_plan.dart';

/// Everything worth knowing about how one exercise page is used, in one place,
/// so the page and its log dialog stay free of event plumbing.
///
/// **What is sent about the exercise:** its position in the workout, its set
/// count, and the *muscle* it trains (one of a fixed set of slugs). **Never its
/// name.** Plans are written by an AI, but users can also add exercises, and
/// that name is free text — the same reason chat messages are only ever
/// recorded by length. The muscle answers "what do people do" without that risk.
///
/// One instance per page visit: it remembers when the page opened and whether
/// the visit has already ended, so an exercise is reported as completed *or*
/// left, never both.
class ExerciseAnalytics {
  final int _index;
  final int _sets;
  final String _muscle;
  final DateTime Function() _now;
  final DateTime _openedAt;

  bool _ended = false;
  bool _usedVoice = false;
  bool _usedLastTime = false;

  ExerciseAnalytics(Exercise exercise, int index, {DateTime Function()? now})
      : _index = index,
        _sets = exercise.sets,
        _muscle = primaryMuscle(exercise),
        _now = now ?? DateTime.now,
        _openedAt = (now ?? DateTime.now)();

  /// The first muscle the plan names for this exercise, or `unknown`. Uses the
  /// same reading of the plan's notes as the muscle map, so the two agree.
  static String primaryMuscle(Exercise e) {
    final muscles =
        MuscleCoverage.musclesFor(name: e.name, notes: e.notes ?? '');
    return muscles.isEmpty ? 'unknown' : muscles.first;
  }

  Map<String, Object?> get _base => {
        'exercise_index': _index,
        'sets': _sets,
        'muscle': _muscle,
      };

  int get _secondsOnPage => _now().difference(_openedAt).inSeconds;

  // ── The page ────────────────────────────────────────────────────────────────

  void viewed() => Analytics.track(AnalyticsEvents.exerciseViewed, _base);

  /// How the history lookup went: `ok`, `empty` (nothing logged yet) or
  /// `failed` (could not read the sessions).
  void historyLoaded(ExerciseHistory? history) {
    Analytics.track(AnalyticsEvents.exerciseHistoryLoaded, {
      'status': history == null
          ? 'failed'
          : history.isEmpty
              ? 'empty'
              : 'ok',
      'entries': history?.length ?? 0,
    });
  }

  /// Mark Complete. The seconds are how long this visit lasted.
  void completed({required bool logged}) {
    if (_ended) return;
    _ended = true;
    Analytics.track(AnalyticsEvents.exerciseCompleted, {
      ..._base,
      'logged': logged,
      'seconds_on_page': _secondsOnPage,
    });
  }

  /// Leaving without completing. A no-op if the exercise was completed.
  void left({required bool logged}) {
    if (_ended) return;
    _ended = true;
    Analytics.track(AnalyticsEvents.exerciseLeft, {
      ..._base,
      'logged': logged,
      'seconds_on_page': _secondsOnPage,
    });
  }

  /// The "Save before leaving?" dialog: `save`, `discard`, or `dismissed`.
  void leavePrompt(String choice) =>
      Analytics.track(AnalyticsEvents.exerciseLeavePrompt, {'choice': choice});

  // ── The log dialog ──────────────────────────────────────────────────────────

  void logOpened({required bool hadPrevious}) {
    _usedVoice = false;
    _usedLastTime = false;
    Analytics.track(AnalyticsEvents.exerciseLogOpened,
        {..._base, 'had_previous': hadPrevious});
  }

  /// Voice logging: `started`, `parsed` (with how many sets it filled) or
  /// `failed`. Only the outcome is recorded, never what was said.
  void voice(String result, {int? sets}) {
    if (result == 'parsed') _usedVoice = true;
    Analytics.track(AnalyticsEvents.exerciseLogVoice, {
      'result': result,
      if (sets != null) 'sets_filled': sets,
    });
  }

  void sameAsLast() {
    _usedLastTime = true;
    Analytics.track(AnalyticsEvents.exerciseLogSameAsLast, _base);
  }

  /// Save was tapped with weight or reps missing for [missing] sets.
  void logIncomplete(int missing) => Analytics.track(
      AnalyticsEvents.exerciseLogIncomplete, {..._base, 'missing_sets': missing});

  void logSaved() => Analytics.track(AnalyticsEvents.exerciseLogSaved, {
        ..._base,
        'used_voice': _usedVoice,
        'used_last_time': _usedLastTime,
      });

  void logSaveFailed() =>
      Analytics.track(AnalyticsEvents.exerciseLogSaveFailed, _base);

  /// The dialog was closed without saving (the X, or a tap outside it).
  void logDismissed() =>
      Analytics.track(AnalyticsEvents.exerciseLogDismissed, _base);

  // ── Tutorials ───────────────────────────────────────────────────────────────

  void tutorialsLoaded(
          {required bool success, int? count, bool cached = false}) =>
      Analytics.track(AnalyticsEvents.exerciseTutorialsLoaded, {
        'success': success,
        'cached': cached,
        if (count != null) 'count': count,
      });

  /// A tutorial video was actually opened (past the paywall).
  void tutorialOpened() =>
      Analytics.track(AnalyticsEvents.exerciseTutorialOpened, _base);
}
