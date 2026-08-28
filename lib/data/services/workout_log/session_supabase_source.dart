import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads workout sessions straight from Supabase.
///
/// The same rows the backend serves, without the hop through Cloud Run. That
/// service scales to zero, so a first read of the day waits ~20s on a cold
/// start before any history appears — for a plain select of the user's own
/// rows, the round trip buys nothing.
///
/// Safe because `workout_sessions` already has row-level security: the
/// `users manage own sessions` policy scopes every client read to
/// `auth.uid() = user_id`. The anon key cannot widen that, so a signed-in user
/// sees their sessions and nobody else's.
///
/// Reads only. Writes stay on the backend, which also generates the session
/// analysis and the coaching feedback.
class SessionSupabaseSource {
  final SupabaseClient _client;

  SessionSupabaseSource(this._client);

  static const String _table = 'workout_sessions';

  /// Sessions for the signed-in user, newest first.
  ///
  /// Returns null — not an empty list — when the read fails, so callers can
  /// tell "nothing logged yet" apart from "we could not reach the database"
  /// and fall back rather than showing a misleading empty state.
  Future<List<WorkoutSessionModel>?> listSessions({int limit = 200}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final rows = await _client
          .from(_table)
          // The policy already restricts rows to this user; filtering as well
          // lets Postgres use the (user_id, session_date) index instead of
          // scanning and discarding.
          .select()
          .eq('user_id', userId)
          .order('session_date', ascending: false)
          .limit(limit);

      return (rows as List)
          .map((r) => WorkoutSessionModel.fromJson(
              Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      debugPrint('SessionSupabaseSource.listSessions failed — $e');
      return null;
    }
  }
}
