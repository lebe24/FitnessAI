import 'dart:async';

import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/models/exercise_history.dart';

/// Reads the user's sessions. Null means "could not reach the database", which
/// is different from an empty list ("nothing logged yet").
typedef SessionFetcher = Future<List<WorkoutSessionModel>?> Function();

/// Answers "what did I do last time for this exercise?".
///
/// Every exercise page asks, and one workout opens six or seven of them. The
/// answer for all of them comes from the same list of sessions, so that list is
/// fetched once and reused for a couple of minutes instead of once per page.
/// A save invalidates it, so a log just made shows up straight away.
class ExerciseHistoryService {
  final SessionFetcher _fetch;
  final Duration _ttl;
  final DateTime Function() _now;

  List<WorkoutSessionModel>? _sessions;
  DateTime? _fetchedAt;
  Future<List<WorkoutSessionModel>?>? _inFlight;

  ExerciseHistoryService({
    required SessionFetcher fetch,
    Duration ttl = const Duration(minutes: 2),
    DateTime Function()? now,
  })  : _fetch = fetch,
        _ttl = ttl,
        _now = now ?? DateTime.now;

  /// History for [exerciseName], or null when sessions could not be read.
  Future<ExerciseHistory?> load(String exerciseName, {int limit = 20}) async {
    final sessions = await _sessionsCached();
    if (sessions == null) return null;
    return ExerciseHistory.fromSessions(sessions, exerciseName, limit: limit);
  }

  /// Drop the cached sessions — call after saving a workout.
  void invalidate() {
    _sessions = null;
    _fetchedAt = null;
  }

  bool get _fresh =>
      _sessions != null &&
      _fetchedAt != null &&
      _now().difference(_fetchedAt!) < _ttl;

  Future<List<WorkoutSessionModel>?> _sessionsCached() {
    if (_fresh) return Future.value(_sessions);
    // Several pages can ask at once; they share one request.
    return _inFlight ??= _fetch().then((result) {
      if (result != null) {
        _sessions = result;
        _fetchedAt = _now();
      }
      return result;
    }).catchError((Object _) => null).whenComplete(() => _inFlight = null);
  }
}
