import 'package:dio/dio.dart';
import 'package:fitness/domain/energy/energy_estimate.dart';
import 'package:fitness/domain/energy/energy_session.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum EnergyError { premiumRequired, rateLimited, offline, server }

class EnergyTurn {
  final bool fromUser;
  final String text;
  const EnergyTurn(this.text, {this.fromUser = false});
}

/// A question, with everything the bot needs to answer it. All figures were
/// worked out on the phone.
class EnergyAsk {
  final String question;
  final String botName;
  final EnergySession session;
  final EnergyEstimate estimate;

  /// What has been said so far, oldest first.
  final List<EnergyTurn> history;

  const EnergyAsk({
    required this.question,
    required this.botName,
    required this.session,
    required this.estimate,
    this.history = const [],
  });
}

class EnergyReply {
  final String text;

  /// False when this is the app's own wording, because the coach could not be
  /// reached or answered unusably.
  final bool fromModel;
  final EnergyError? error;

  const EnergyReply(this.text, {this.fromModel = false, this.error});

  /// The app's own answer from the same figures.
  factory EnergyReply.fallback(EnergyAsk ask, [EnergyError? error]) {
    if (error == EnergyError.premiumRequired) {
      return const EnergyReply('Chatting with me is part of BeFit Pro.',
          error: EnergyError.premiumRequired);
    }
    if (error == EnergyError.rateLimited) {
      return const EnergyReply('That\'s a lot of questions! Give me a minute and ask again.',
          error: EnergyError.rateLimited);
    }
    final e = ask.estimate;
    final estimate = '${e.lowKcal} to ${e.highKcal} kcal';
    final q = ask.question.toLowerCase();
    bool has(List<String> words) => words.any(q.contains);

    final String text;
    if (q.contains('how') && has(['work', 'calculat', 'get'])) {
      final level = e.effort.level;
      text = 'I rate this as ${level.label.toLowerCase()} effort, ${_met(level.lowMet)} to '
          '${_met(level.highMet)} on the activity scale (MET). That times your body weight and '
          '${e.minutes} minutes gives $estimate.';
    } else if (has(['food', 'banana', 'eat', 'egg'])) {
      text = e.equivalents.isEmpty
          ? 'Your estimate is $estimate.'
          : '$estimate is roughly ${e.equivalents.map((x) => x.words).join(', or ')}.';
    } else if (has(['range', 'accura', 'exact'])) {
      text = 'I can\'t see your heart rate, and effort and rest change the figure. '
          'It also includes the energy you\'d use resting.';
    } else {
      text = 'I can\'t answer that just now. Your estimate for this session is $estimate.';
    }
    return EnergyReply(text, error: error);
  }

  static String _met(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
}

abstract class EnergyResponder {
  /// Never throws: a failure comes back as the app's own answer.
  Future<EnergyReply> reply(EnergyAsk ask);
}

/// Answers from the app's own wording only. For previews.
class LocalEnergyResponder implements EnergyResponder {
  const LocalEnergyResponder();

  @override
  Future<EnergyReply> reply(EnergyAsk ask) async => EnergyReply.fallback(ask);
}

class DioEnergyCoach implements EnergyResponder {
  final Dio _dio;

  DioEnergyCoach({Dio? dio}) : _dio = dio ?? _build();

  static Dio _build() {
    final dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 25),
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
  Future<EnergyReply> reply(EnergyAsk ask) async {
    try {
      final r = await _dio.post('/api/v1/energy/chat', data: toJson(ask));
      final data = r.data as Map;
      final text = (data['reply'] as String?)?.trim() ?? '';
      if (text.isEmpty) return EnergyReply.fallback(ask, EnergyError.server);
      return EnergyReply(text, fromModel: data['source'] == 'model');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = e.response?.data is Map ? (e.response!.data as Map)['detail'] : null;
      final code = detail is Map ? detail['code'] : null;
      return EnergyReply.fallback(
        ask,
        status == 403 && code == 'premium_required'
            ? EnergyError.premiumRequired
            : status == 429
                ? EnergyError.rateLimited
                : status == null
                    ? EnergyError.offline
                    : EnergyError.server,
      );
    } catch (_) {
      return EnergyReply.fallback(ask, EnergyError.server);
    }
  }

  static String _clip(String s, int max) => s.length <= max ? s : s.substring(0, max);

  /// The request body. Lengths and counts are cut to what the server accepts.
  static Map<String, dynamic> toJson(EnergyAsk a) {
    final s = a.session;
    final e = a.estimate;
    final recent = a.history.length > 8 ? a.history.sublist(a.history.length - 8) : a.history;
    return {
      'question': _clip(a.question, 300),
      'bot_name': _clip(a.botName, 40),
      'history': [
        for (final t in recent) {'role': t.fromUser ? 'user' : 'bot', 'text': _clip(t.text, 500)}
      ],
      'session': {
        'title': _clip(s.title, 60),
        'minutes': e.minutes.clamp(1, 600),
        'sets': s.sets.clamp(0, 300),
        'volume_kg': s.volumeKg.clamp(0, 500000).round(),
        'exercises': [
          for (final x in s.exercises.take(30))
            {
              'name': _clip(x.name.isEmpty ? 'Exercise' : x.name, 80),
              'sets': [for (final set in x.sets.take(20)) _clip(set, 40)],
            }
        ],
      },
      'estimate': {
        'low_kcal': e.lowKcal,
        'high_kcal': e.highKcal,
        'weight_kg': double.parse(e.weightKg.toStringAsFixed(1)),
        'effort': e.effort.level.name,
        'effort_reason': _clip(e.effort.reason, 200),
        'low_met': e.effort.level.lowMet,
        'high_met': e.effort.level.highMet,
      },
      'equivalents': [
        for (final x in e.equivalents) {'label': x.label, 'amount': x.amount.clamp(0, 2000)}
      ],
    };
  }
}
