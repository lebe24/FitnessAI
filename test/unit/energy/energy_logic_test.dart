import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/energy/bot_settings_store.dart';
import 'package:fitness/data/services/energy/energy_coach_service.dart';
import 'package:fitness/domain/energy/bot_settings.dart';
import 'package:fitness/domain/energy/energy_effort.dart';
import 'package:fitness/domain/energy/energy_estimate.dart';
import 'package:fitness/domain/energy/energy_session.dart';
import 'package:fitness/ui/features/energy/view_models/bot_settings_controller.dart';
import 'package:fitness/ui/features/energy/view_models/energy_chat_controller.dart';
import 'package:fitness/ui/features/energy/views/finished_session.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSessionModel _session({int? minutes = 60, String? id, List<(String, String)>? logs}) =>
    WorkoutSessionModel(
      id: id,
      sessionDate: DateTime(2026, 11, 24),
      dayLabel: 'Tuesday',
      durationMins: minutes,
      workoutLogs: [
        for (final (name, notes) in logs ??
            [
              ('Barbell Squat', 'set 1: 10 reps @ 60kg | set 2: 8 reps @ 62.5kg'),
              ('Hanging Leg Raise', 'set 1: 12 reps @ 0kg | set 2: 0 reps'),
              ('Plank', 'set 1: 45 sec'),
              ('Leg Curl', 'abs | Squeeze at the top'),
            ])
          {'name': name, 'notes': notes}
      ],
    );

class _Responder implements EnergyResponder {
  final asked = <EnergyAsk>[];
  EnergyReply answer = const EnergyReply('Sure thing.', fromModel: true);
  bool explode = false;

  @override
  Future<EnergyReply> reply(EnergyAsk ask) async {
    asked.add(ask);
    if (explode) throw StateError('boom');
    return answer;
  }
}

class _Adapter implements HttpClientAdapter {
  final int status;
  final Object body;
  RequestOptions? seen;
  _Adapter(this.status, this.body);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    seen = options;
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

EnergyAsk _ask(String question, {List<EnergyTurn> history = const []}) => EnergyAsk(
      question: question,
      botName: 'Coach Mo',
      session: EnergySession.of(_session()),
      estimate: EnergyEstimate.of(weightKg: 80, minutes: 60),
      history: history,
    );

DioEnergyCoach _coach(_Adapter adapter) =>
    DioEnergyCoach(dio: Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = adapter);

EnergyChatController _chat(_Responder r, {int? minutes = 60, double? kg = 80, bool imperial = false}) =>
    EnergyChatController(
      facts: EnergyFacts(session: EnergySession.of(_session(minutes: minutes)), weightKg: kg, imperial: imperial),
      responder: r,
      botName: 'BeFit Bot',
      typingDelay: Duration.zero,
    );

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 5));

List<String> _said(EnergyChatController c) =>
    [for (final m in c.messages) if (m is BotText) m.text];

void main() {
  group('effort', () {
    EffortLevel level(int sets, int minutes, [int big = 0]) =>
        EffortRating.of(sets: sets, minutes: minutes, bigLiftSets: big).level;

    test('follows the pace of the sets', () {
      expect(level(10, 60), EffortLevel.light);
      expect(level(21, 60), EffortLevel.moderate);
      expect(level(30, 60), EffortLevel.hard);
    });

    test('big leg lifts make a brisk pace hard', () {
      expect(level(25, 60), EffortLevel.moderate);
      expect(level(25, 60, 13), EffortLevel.hard);
      expect(level(21, 60, 21), EffortLevel.moderate);
    });

    test('is moderate, and says so, with no sets', () {
      final r = EffortRating.of(sets: 0, minutes: 60);
      expect(r.level, EffortLevel.moderate);
      expect(r.reason, contains('No sets'));
    });

    test('knows the big lifts by name', () {
      for (final n in ['Barbell Squat', 'Romanian Deadlift', 'Smith machine RDL', 'Walking Lunges', 'Leg Press']) {
        expect(EffortRating.isBigLift(n), isTrue, reason: n);
      }
      for (final n in ['Bench Press', 'Leg Curl', 'Hurdle Hop', 'Cable Crunch']) {
        expect(EffortRating.isBigLift(n), isFalse, reason: n);
      }
    });
  });

  group('estimate', () {
    test('is MET × weight × hours, to the nearest 10', () {
      final e = EnergyEstimate.of(weightKg: 80, minutes: 60);
      expect((e.lowKcal, e.highKcal), (280, 400));
    });

    test('moves with effort', () {
      final e = EnergyEstimate.of(
          weightKg: 80, minutes: 60, effort: const EffortRating(EffortLevel.hard, ''));
      expect((e.lowKcal, e.highKcal), (400, 480));
    });

    test('speaks in everyday terms, singular when one', () {
      final e = EnergyEstimate.of(weightKg: 80, minutes: 60);
      expect([for (final x in e.equivalents) x.words],
          ['3 medium bananas', '4 boiled eggs', '67 minutes of walking']);
      expect(const EnergyEquivalent('medium bananas', 1).words, '1 medium banana');
      expect(const EnergyEquivalent('minutes of walking', 1).words, '1 minute of walking');
      expect(EnergyEstimate.of(weightKg: 50, minutes: 5).equivalents.map((x) => x.amount),
          everyElement(greaterThan(0)));
    });
  });

  group('session', () {
    test('counts only the sets performed', () {
      final s = EnergySession.of(_session());
      expect(s.title, 'Tuesday');
      expect(s.sets, 4);
      expect(s.bigLiftSets, 2);
      expect(s.volumeKg, 10 * 60 + 8 * 62.5);
      expect(s.exercises.map((e) => e.name), ['Barbell Squat', 'Hanging Leg Raise', 'Plank']);
      expect(s.exercises.first.sets, ['10 x 60 kg', '8 x 62.5 kg']);
      expect(s.exercises[1].sets, ['12 reps']);
      expect(s.exercises[2].sets, ['45 sec']);
    });

    test('a missing duration is unknown, not zero', () {
      expect(EnergySession.of(_session(minutes: 0)).minutes, isNull);
      expect(EnergySession.of(_session(minutes: null)).minutes, isNull);
    });
  });

  group('bot settings', () {
    test('names are reduced to names', () {
      expect(BotSettings.cleanName('  Coach   Mo '), 'Coach Mo');
      expect(BotSettings.cleanName('Zoë-Ann O\'Neil'), 'Zoë-Ann O\'Neil');
      expect(BotSettings.cleanName('Bot"}\n{ignore'), 'Bot ignore');
      expect(BotSettings.cleanName('a' * 40), 'a' * 20);
      expect(BotSettings.cleanName(' !!! '), 'BeFit Bot');
      expect(BotSettings.cleanName(''), 'BeFit Bot');
    });

    test('default to BeFit Bot as the flame', () {
      expect(const BotSettings().name, 'BeFit Bot');
      expect(const BotSettings().mascot, BotMascot.flame);
    });

    test('are loaded, saved clean and announced', () async {
      final store = MemoryBotSettingsStore(const BotSettings(name: 'Mo', mascot: BotMascot.robot));
      final c = BotSettingsController(store);
      var told = 0;
      c.addListener(() => told++);
      await c.loaded;
      expect(c.value.name, 'Mo');

      expect(await c.save(const BotSettings(name: '  Rex!! ', mascot: BotMascot.droplet)), isTrue);
      expect(store.saved, const BotSettings(name: 'Rex', mascot: BotMascot.droplet));
      expect(c.value, store.saved);
      expect(told, 2);
    });

    test('a change made while loading is not overwritten', () async {
      final c = BotSettingsController(MemoryBotSettingsStore(const BotSettings(name: 'Old')));
      await c.save(const BotSettings(name: 'New'));
      await c.loaded;
      expect(c.value.name, 'New');
    });
  });

  group('conversation', () {
    test('greets then shows the estimate', () async {
      final c = _chat(_Responder());
      await c.start();
      expect(_said(c).first, 'Nice work! 4 sets in the bag 💪');
      expect(c.estimate, isNotNull);
      expect(c.openSuggestions, EnergyChatController.suggestions);
    });

    test('asks for a missing duration and weight, rejecting nonsense', () async {
      final c = _chat(_Responder(), minutes: null, kg: null);
      await c.start();
      expect(c.waitingFor, EnergyQuestion.duration);
      expect(c.send('about an hour'), isFalse); // kept in the box
      expect(c.send('900 min'), isTrue);
      await _settle();
      expect(c.waitingFor, EnergyQuestion.duration);
      c.send('45 min');
      await _settle();
      expect(c.waitingFor, EnergyQuestion.weight);
      c.send('3');
      await _settle();
      expect(c.waitingFor, EnergyQuestion.weight);
      c.send('72,5');
      await _settle();
      expect(c.estimate!.weightKg, 72.5);
      expect(c.estimate!.minutes, 45);
    });

    test('takes weight in pounds', () async {
      final c = _chat(_Responder(), kg: null, imperial: true);
      await c.start();
      expect(_said(c).last, contains('lb'));
      await c.pickWeight(176);
      expect(c.estimate!.weightKg, closeTo(79.8, 0.1));
    });

    test('sends questions with the figures and what was said', () async {
      final r = _Responder();
      final c = _chat(r);
      await c.start();
      c.send('Why a range?');
      await _settle();
      final ask = r.asked.single;
      expect(ask.question, 'Why a range?');
      expect(ask.estimate, same(c.estimate));
      expect(ask.history.last.text, startsWith('Estimate shown:'));
      expect(ask.history.where((t) => t.fromUser), isEmpty);
      expect(_said(c).last, 'Sure thing.');
      expect(c.openSuggestions, isNot(contains('Why a range?')));
    });

    test('marks an answer the coach could not give', () async {
      final r = _Responder()..explode = true;
      final c = _chat(r);
      await c.start();
      c.send('How did you work that out?');
      await _settle();
      final last = c.messages.last as BotText;
      expect(last.offline, isTrue);
      expect(last.text, contains('MET'));
    });
  });

  group('coach service', () {
    test('sends what the server accepts', () async {
      final adapter = _Adapter(200, {'reply': 'Great job', 'source': 'model'});
      final reply = await _coach(adapter).reply(_ask('x' * 400,
          history: [for (var i = 0; i < 12; i++) EnergyTurn('turn $i', fromUser: i.isOdd)]));

      expect(reply.text, 'Great job');
      expect(reply.fromModel, isTrue);
      expect(adapter.seen!.path, '/api/v1/energy/chat');
      final body = adapter.seen!.data as Map;
      expect((body['question'] as String).length, 300);
      expect(body['history'], hasLength(8));
      expect((body['history'] as List).first, {'role': 'bot', 'text': 'turn 4'});
      expect(body['bot_name'], 'Coach Mo');
      expect(body['estimate'], containsPair('low_kcal', 280));
      expect(body['estimate'], containsPair('effort', 'moderate'));
      expect((body['session'] as Map)['minutes'], 60);
      expect(body['equivalents'], hasLength(3));
    });

    test('never throws, and says why it fell back', () async {
      Future<EnergyReply> from(int status, Object body) =>
          _coach(_Adapter(status, body)).reply(_ask('What is that in food?'));

      final locked = await from(403, {'detail': {'code': 'premium_required'}});
      expect(locked.error, EnergyError.premiumRequired);
      expect(locked.text, contains('Pro'));
      expect((await from(429, {})).error, EnergyError.rateLimited);
      final down = await from(500, {});
      expect(down.error, EnergyError.server);
      expect(down.text, contains('banana'));
      expect(down.fromModel, isFalse);
      expect((await from(200, {'reply': ' '})).error, EnergyError.server);
      expect((await from(200, 'nonsense')).error, EnergyError.server);
    });

    test("the server's fixed wording is not marked as the model", () async {
      final r = await _coach(_Adapter(200, {'reply': 'Fixed', 'source': 'template'})).reply(_ask('hi'));
      expect(r.fromModel, isFalse);
      expect(r.error, isNull);
    });
  });

  group('the finished session', () {
    final saved = _session(id: 'a');

    test('uses the stored copy when it has everything', () {
      final stored = _session(id: 'a', minutes: 61);
      expect(latestCopy(saved, [_session(id: 'b'), stored]), same(stored));
    });

    test('keeps what was just saved when the copy is older or missing', () {
      final older = _session(id: 'a', logs: [('Squat', 'set 1: 5 reps @ 60kg')]);
      expect(latestCopy(saved, [older]), same(saved));
      expect(latestCopy(saved, null), same(saved));
      expect(latestCopy(_session(), [saved]).id, isNull);
    });
  });
}
