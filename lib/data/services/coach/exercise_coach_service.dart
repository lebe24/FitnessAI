import 'package:dio/dio.dart';
import 'package:fitness/domain/coach/exercise_catalog.dart';
import 'package:fitness/domain/coach/exercise_recommendation.dart';
import 'package:fitness/domain/coach/session_load.dart';
import 'package:fitness/domain/models/muscle_coverage.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/progression/progression_engine.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// What the person tapped: why these numbers, suggest an exercise, or build a
/// short extra workout.
enum CoachAsk { why, suggest, workout }

enum ExerciseCoachError { premiumRequired, rateLimited, offline, server }

/// Everything the coach is told. All of it was worked out on the phone.
class ExerciseCoachRequest {
  final CoachAsk ask;
  final GoalKind goal;
  final String? experience;
  final Exercise exercise;
  final ExerciseRecommendation recommendation;

  /// Recent visits, newest first, as `Nov 23: 3 × 10 @ 60 kg`.
  final List<String> history;
  final List<Exercise> today;
  final SessionLoad load;
  final List<Suggestion> candidates;

  const ExerciseCoachRequest({
    required this.ask,
    required this.goal,
    required this.exercise,
    required this.recommendation,
    required this.load,
    this.experience,
    this.history = const [],
    this.today = const [],
    this.candidates = const [],
  });
}

class CoachAnswer {
  /// Why the numbers suit this person.
  final String note;

  /// Whether to add anything.
  final String sessionAdvice;
  final List<Suggestion> picks;

  /// False when this is the app's own wording, because the coach could not be
  /// reached or answered unusably.
  final bool fromModel;
  final ExerciseCoachError? error;

  const CoachAnswer({
    required this.note,
    required this.sessionAdvice,
    required this.picks,
    required this.fromModel,
    this.error,
  });

  /// The app's own answer, from the same rules the request was built with.
  factory CoachAnswer.fallback(ExerciseCoachRequest r, [ExerciseCoachError? error]) => CoachAnswer(
        note: r.recommendation.reason,
        sessionAdvice: r.load.advice,
        picks: r.ask == CoachAsk.workout
            ? ExerciseSuggester.workout(r.candidates, roomSets: r.load.roomSets)
            : r.candidates.take(3).toList(),
        fromModel: false,
        error: error,
      );
}

abstract class ExerciseCoach {
  /// Never throws: a failure comes back as the app's own answer.
  Future<CoachAnswer> ask(ExerciseCoachRequest request);
}

class DioExerciseCoach implements ExerciseCoach {
  final Dio _dio;

  DioExerciseCoach({Dio? dio}) : _dio = dio ?? _build();

  static Dio _build() {
    final dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 25), // someone is waiting in the gym
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

  @override
  Future<CoachAnswer> ask(ExerciseCoachRequest request) async {
    try {
      final r = await _dio.post('/api/v1/exercise/coach', data: toJson(request));
      return fromJson(request, Map<String, dynamic>.from(r.data as Map));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = e.response?.data is Map ? (e.response!.data as Map)['detail'] : null;
      final code = detail is Map ? detail['code'] : null;
      final error = status == 403 && code == 'premium_required'
          ? ExerciseCoachError.premiumRequired
          : status == 429
              ? ExerciseCoachError.rateLimited
              : status == null
                  ? ExerciseCoachError.offline
                  : ExerciseCoachError.server;
      return CoachAnswer.fallback(request, error);
    } catch (_) {
      return CoachAnswer.fallback(request, ExerciseCoachError.server);
    }
  }

  static String _clip(String s, int max) => s.length <= max ? s : s.substring(0, max);

  static const _soreness = {
    Soreness.fresh: 'fresh',
    Soreness.aBitSore: 'a_bit_sore',
    Soreness.verySore: 'very_sore',
  };

  /// The request body. Lengths and counts are cut to what the server accepts.
  static Map<String, dynamic> toJson(ExerciseCoachRequest r) {
    final rec = r.recommendation;
    return {
      'mode': r.ask == CoachAsk.workout ? 'workout' : 'advice',
      'goal': r.goal.name,
      'experience': r.experience == null ? null : _clip(r.experience!, 30),
      'soreness': _soreness[r.load.soreness],
      'exercise': {
        'name': _clip(r.exercise.name, 80),
        'sets': r.exercise.sets.clamp(1, 20),
        'reps': _clip(r.exercise.reps, 20),
        'target_kg': r.exercise.targetKg,
      },
      'recommendation': {
        'action': rec.action.name,
        'badge': _clip(rec.badge, 30),
        'label': _clip(rec.target.label, 60),
        'reason': _clip(rec.reason, 300),
        'goal_range': rec.goalRange.label,
        'alternative': rec.alternative == null ? null : _clip(rec.alternative!.label, 60),
      },
      'history': [for (final h in r.history.take(8)) _clip(h, 80)],
      'today': [
        for (final e in r.today.take(30))
          {
            'name': _clip(e.name, 80),
            'sets': e.sets.clamp(0, 30),
            'muscles': MuscleCoverage.musclesFor(name: e.name, notes: e.notes ?? '').take(8).toList(),
          }
      ],
      'muscles': [
        for (final v in r.load.trainedToday.take(14))
          {'group': v.group.label.toLowerCase(), 'today': v.today, 'week': v.week, 'target': v.target}
      ],
      'verdict': r.load.verdict.name,
      'verdict_text': _clip('${r.load.headline}. ${r.load.advice}', 500),
      'room_sets': r.load.roomSets.clamp(0, 30),
      'candidates': [
        for (final s in r.candidates.take(12))
          {
            'id': s.exercise.id,
            'name': s.exercise.name,
            'muscle': s.exercise.primary.label.toLowerCase(),
            'sets': s.sets,
            'reps': s.reps,
            'weight_kg': s.weightKg,
            'why': _clip(s.why, 200),
          }
      ],
    };
  }

  /// The server only returns ids, set counts and sentences. Anything it names
  /// that was not offered is ignored, and set counts are held to 2–4.
  static CoachAnswer fromJson(ExerciseCoachRequest r, Map<String, dynamic> json) {
    final offered = {for (final s in r.candidates) s.exercise.id: s};
    final picks = <Suggestion>[];
    for (final raw in (json['picks'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final base = offered.remove(raw['id']);
      if (base == null) continue;
      final sets = (raw['sets'] as num?)?.toInt() ?? base.sets;
      final why = (raw['why'] as String?)?.trim();
      picks.add(base.copyWith(sets: sets.clamp(2, 4), why: why == null || why.isEmpty ? null : why));
    }
    final note = (json['note'] as String?)?.trim() ?? '';
    if (note.isEmpty) return CoachAnswer.fallback(r, ExerciseCoachError.server);
    return CoachAnswer(
      note: note,
      sessionAdvice: (json['session_advice'] as String?)?.trim() ?? r.load.advice,
      picks: picks,
      fromModel: json['source'] == 'model',
    );
  }
}
