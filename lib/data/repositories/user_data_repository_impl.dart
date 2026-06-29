import 'package:fitness/data/services/workout_log/workout_log_remote_service.dart';
import 'package:fitness/domain/repositories/user_data_repository.dart';

/// Implements UserDataRepository using the backend workout_sessions API.
///
/// The old implementation queried a `user_data` Supabase table that doesn't
/// exist. All the same data lives in `workout_sessions` via the backend API.
class UserDataRepositoryImpl implements UserDataRepository {
  final WorkoutLogRemoteDataSource _remote;

  UserDataRepositoryImpl(this._remote);

  // ── getUserStreak ──────────────────────────────────────────────────────────

  @override
  Future<int> getUserStreak(String userId) async {
    try {
      final streak = await _remote.getStreak();
      return streak.currentStreak;
    } catch (_) {
      return 0;
    }
  }

  // ── getUserData ────────────────────────────────────────────────────────────
  //
  // statistics_page.dart expects a list containing one map with a
  // `date_n_duration` key:
  //   [{ "date_n_duration": [{"date": ISO, "duration": double}, ...] }]
  //
  // We build that from the completed workout sessions.

  @override
  Future<List<Map<String, dynamic>>> getUserData(String userId) async {
    try {
      final sessions = await _remote.listSessions(limit: 100);
      final completed = sessions
          .where((s) => s.isCompleted && s.durationMins != null)
          .toList();

      final dateNDuration = completed.map((s) => {
            'date': s.sessionDate.toIso8601String(),
            'duration': (s.durationMins ?? 0).toDouble(),
          }).toList();

      return [
        {'date_n_duration': dateNDuration}
      ];
    } catch (_) {
      return [];
    }
  }

  // ── getCompletedDates ──────────────────────────────────────────────────────

  @override
  Future<Set<DateTime>> getCompletedDates(String userId) async {
    try {
      final sessions = await _remote.listSessions(limit: 100);
      return sessions
          .where((s) => s.isCompleted)
          .map((s) => DateTime(
                s.sessionDate.year,
                s.sessionDate.month,
                s.sessionDate.day,
              ))
          .toSet();
    } catch (_) {
      return {};
    }
  }

  // ── isWorkoutCompletedForDate ──────────────────────────────────────────────

  @override
  Future<bool> isWorkoutCompletedForDate(String userId, DateTime date) async {
    try {
      final dates = await getCompletedDates(userId);
      final normalized = DateTime(date.year, date.month, date.day);
      return dates.contains(normalized);
    } catch (_) {
      return false;
    }
  }

  // ── updateWorkoutCompletion ────────────────────────────────────────────────
  //
  // The old implementation wrote directly to the `user_data` table.
  // Session completion is now handled by WorkoutLogViewModel.finishSession()
  // which calls PATCH /api/v1/logs/sessions/{id}. This method is kept for
  // compatibility but is a no-op — callers should use the workout log flow.

  @override
  Future<void> updateWorkoutCompletion({
    required String userId,
    required double duration,
    required DateTime date,
  }) async {
    // No-op: use WorkoutLogViewModel.finishSession() to complete sessions.
  }
}
