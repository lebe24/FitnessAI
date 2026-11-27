import 'package:dio/dio.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/progression/progression_engine.dart';
import 'package:fitness/domain/progression/progression_proposal.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Asks the coach to review a proposed plan update.
abstract class CoachReviewer {
  /// Never throws. If the coach cannot be reached, or is not allowed, the
  /// result has `reviewed: false` and the changes stand as the rules proposed.
  Future<CoachResult> review(
    ProgressionProposal proposal, {
    required ProgressionSettings settings,
    GoalType? goalType,
    List<MuscleGroup> focus = const [],
  });
}

class DioCoachReviewer implements CoachReviewer {
  late final Dio _dio;

  DioCoachReviewer({Dio? dio}) {
    _dio = dio ?? _build();
  }

  static Dio _build() {
    final dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 20),
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
    ));
    return dio;
  }

  static const _unreviewed = CoachResult(decisions: {}, reviewed: false);

  @override
  Future<CoachResult> review(
    ProgressionProposal proposal, {
    required ProgressionSettings settings,
    GoalType? goalType,
    List<MuscleGroup> focus = const [],
  }) async {
    // Holds have nothing to review. Ids follow the proposal's own order so the
    // answer can be matched back even after holds are left out.
    final sent = <Map<String, dynamic>>[];
    for (var i = 0; i < proposal.changes.length; i++) {
      final c = proposal.changes[i];
      if (c.isHold) continue;
      sent.add({
        'id': 'c$i',
        'exercise': c.exercise,
        'kind': c.kind.name,
        'before': c.before,
        'after': c.after,
        'badge': c.badge,
        'reason': c.reason,
      });
    }
    if (sent.isEmpty) return _unreviewed;

    try {
      final r = await _dio.post('/api/v1/coach/review', data: {
        'goal': proposal.goal,
        if (goalType != null) 'goal_type': goalType.api,
        'pace': settings.pace.name,
        'focus_muscles': [for (final m in focus) m.api],
        'sessions_analysed': proposal.sessionsAnalysed,
        'adherence': proposal.adherence.clamp(0.0, 1.0),
        'is_deload': proposal.isDeload,
        'changes': sent,
      });
      final data = Map<String, dynamic>.from(r.data as Map);
      if (data['reviewed'] != true) return _unreviewed;

      final decisions = <String, CoachDecision>{};
      for (final v in (data['verdicts'] as List? ?? const [])) {
        final m = Map<String, dynamic>.from(v as Map);
        final verdict = switch (m['verdict']) {
          'soften' => CoachVerdict.soften,
          'veto' => CoachVerdict.veto,
          _ => CoachVerdict.approve,
        };
        decisions[m['id'] as String] = CoachDecision(verdict, m['reason'] as String?);
      }
      return CoachResult(decisions: decisions, note: data['note'] as String?, reviewed: true);
    } catch (e) {
      // Pro-only on the server, so a free user lands here too. Either way the
      // plan update carries on without the review.
      debugPrint('CoachReview: skipped — $e');
      return _unreviewed;
    }
  }
}
