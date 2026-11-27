import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness/data/services/coach/exercise_coach_service.dart';
import 'package:fitness/domain/coach/exercise_catalog.dart';
import 'package:fitness/domain/coach/exercise_recommendation.dart';
import 'package:fitness/domain/coach/session_load.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/progression/progression_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'coach_fixtures.dart';

const _bench = Exercise(name: 'Bench Press', sets: 3, reps: '8-10', targetKg: 60, notes: 'chest, triceps | x');

ExerciseCoachRequest _request({CoachAsk ask = CoachAsk.suggest, Soreness? soreness}) {
  final load = SessionLoad.analyse(today: const [_bench], sessions: const [], now: coachNow, soreness: soreness);
  return ExerciseCoachRequest(
    ask: ask,
    goal: GoalKind.hypertrophy,
    experience: 'Experienced',
    exercise: _bench,
    recommendation: ExerciseRecommendation.of(
        exercise: _bench, history: ExerciseHistory.empty, goal: GoalKind.hypertrophy, now: coachNow),
    history: const ['Nov 23: 3 × 10 @ 60 kg'],
    today: const [_bench],
    load: load,
    candidates: ExerciseSuggester.candidates(today: const [_bench], load: load, goal: GoalKind.hypertrophy),
  );
}

/// Answers every request with [status] and [body], or fails to connect.
class _Adapter implements HttpClientAdapter {
  final int? status;
  final Object body;
  RequestOptions? seen;
  _Adapter(this.status, [this.body = const {}]);

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    seen = o;
    if (status == null) throw DioException(requestOptions: o, type: DioExceptionType.connectionError);
    return ResponseBody.fromString(jsonEncode(body), status!, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

DioExerciseCoach _coach(_Adapter a) => DioExerciseCoach(dio: Dio()..httpClientAdapter = a);

void main() {
  group('what is sent', () {
    test('carries the phone\'s numbers and verdict', () {
      final json = DioExerciseCoach.toJson(_request(soreness: Soreness.aBitSore));
      expect(json['mode'], 'advice');
      expect(json['goal'], 'hypertrophy');
      expect(json['soreness'], 'a_bit_sore');
      expect((json['recommendation'] as Map)['badge'], isNotEmpty);
      expect(json['verdict'], 'room');
      expect((json['today'] as List).single['muscles'], ['chest', 'triceps']);
      expect((json['candidates'] as List).length, inInclusiveRange(1, 12));
    });

    test('a workout asks in workout mode; "why" and "suggest" ask for advice', () {
      expect(DioExerciseCoach.toJson(_request(ask: CoachAsk.workout))['mode'], 'workout');
      expect(DioExerciseCoach.toJson(_request(ask: CoachAsk.why))['mode'], 'advice');
    });
  });

  group('what is accepted back', () {
    test('picks are matched to the offered exercises and sets held to 2–4', () {
      final r = _request();
      final first = r.candidates.first;
      final answer = DioExerciseCoach.fromJson(r, {
        'note': 'Go for it.',
        'session_advice': 'One more fits.',
        'source': 'model',
        'picks': [
          {'id': first.exercise.id, 'sets': 9, 'why': 'Because.'},
          {'id': first.exercise.id, 'sets': 3, 'why': 'Again.'},
          {'id': 'made_up', 'sets': 3, 'why': 'No.'},
        ],
      });
      expect(answer.picks, hasLength(1));
      expect(answer.picks.single.sets, 4);
      expect(answer.picks.single.why, 'Because.');
      expect(answer.picks.single.reps, first.reps);
      expect(answer.fromModel, isTrue);
    });

    test('a template answer is marked as the app\'s own', () {
      final a = DioExerciseCoach.fromJson(_request(), {'note': 'x', 'source': 'template', 'picks': []});
      expect(a.fromModel, isFalse);
    });

    test('an empty note is treated as no answer', () {
      final a = DioExerciseCoach.fromJson(_request(), {'note': ' ', 'picks': []});
      expect(a.error, ExerciseCoachError.server);
      expect(a.picks, isNotEmpty);
    });
  });

  group('failures come back as the app\'s own answer', () {
    Future<CoachAnswer> ask(_Adapter a, {CoachAsk kind = CoachAsk.suggest}) => _coach(a).ask(_request(ask: kind));

    test('no connection', () async {
      final a = await ask(_Adapter(null));
      expect(a.error, ExerciseCoachError.offline);
      expect(a.fromModel, isFalse);
      expect(a.picks, hasLength(3));
      expect(a.note, isNotEmpty);
    });

    test('not Pro, rate limited, and a server error', () async {
      expect((await ask(_Adapter(403, {'detail': {'code': 'premium_required'}}))).error,
          ExerciseCoachError.premiumRequired);
      expect((await ask(_Adapter(429))).error, ExerciseCoachError.rateLimited);
      expect((await ask(_Adapter(404))).error, ExerciseCoachError.server); // not deployed yet
    });

    test('an offline workout is built on the phone', () async {
      final a = await ask(_Adapter(null), kind: CoachAsk.workout);
      expect(a.picks.length, inInclusiveRange(2, 4));
    });

    test('a success is posted to the coach route', () async {
      final adapter = _Adapter(200, {'note': 'Hi', 'source': 'model', 'picks': []});
      final a = await ask(adapter);
      expect(adapter.seen!.path, '/api/v1/exercise/coach');
      expect(a.note, 'Hi');
    });
  });
}
