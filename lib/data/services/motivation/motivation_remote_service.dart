import 'package:dio/dio.dart';
import 'package:fitness/data/services/motivation/motivation_notification_service.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetches AI-written motivational notification copy from the backend.
///
/// The agent is given the user's full profile server-side (name, body stats,
/// goal, streak, recent training), so the client only sends the tone and the
/// delivery slot.
class MotivationRemoteService {
  late final Dio _dio;

  MotivationRemoteService() {
    _dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 30),
      // Generating a week of messages is a single multi-message LLM call.
      receiveTimeout: const Duration(seconds: 90),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
    ));
  }

  /// A batch of messages in [tone] for the given [schedule]
  /// ('morning' | 'evening' | 'HH:mm'). Returns an empty list on failure —
  /// callers surface that as "couldn't reach the coach" rather than crashing.
  Future<List<MotivationMessage>> fetchMessages({
    required String tone,
    required String schedule,
    int count = 7,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/motivation/notifications',
        data: {'tone': tone, 'schedule': schedule, 'count': count},
      );
      final data = res.data;
      if (data is! Map || data['messages'] is! List) return const [];
      return (data['messages'] as List)
          .whereType<Map>()
          .map((m) => MotivationMessage.fromJson(Map<String, dynamic>.from(m)))
          .where((m) => m.body.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('MotivationRemoteService.fetchMessages failed: $e');
      return const [];
    }
  }

  /// A single message in [tone] to read right now.
  ///
  /// Same endpoint as [fetchMessages] — the agent writes from the user's
  /// server-side profile either way — asked for one message on the 'now'
  /// schedule so the copy reads as immediate rather than a scheduled nudge.
  /// Returns null on failure; the caller shows a retry instead of crashing.
  Future<MotivationMessage?> fetchOne({required String tone}) async {
    final messages =
        await fetchMessages(tone: tone, schedule: 'now', count: 1);
    return messages.isEmpty ? null : messages.first;
  }
}
