import 'package:fitness/data/services/analytics/energy_analytics.dart';
import 'package:fitness/data/services/energy/energy_coach_service.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/energy/energy_effort.dart';
import 'package:fitness/domain/energy/energy_estimate.dart';
import 'package:fitness/domain/energy/energy_session.dart';
import 'package:flutter/foundation.dart';

/// What the bot knows when the chat opens.
class EnergyFacts {
  final EnergySession session;

  /// Null when nothing has been logged; the bot then asks.
  final double? weightKg;
  final bool imperial;

  const EnergyFacts({required this.session, this.weightKg, this.imperial = false});
}

sealed class EnergyMessage {
  const EnergyMessage();
}

class BotText extends EnergyMessage {
  final String text;

  /// The app's own wording, shown because the coach could not be reached.
  final bool offline;
  const BotText(this.text, {this.offline = false});
}

class UserText extends EnergyMessage {
  final String text;
  const UserText(this.text);
}

class EnergyResult extends EnergyMessage {
  final EnergyEstimate estimate;
  const EnergyResult(this.estimate);
}

enum EnergyQuestion { none, duration, weight }

enum BotMood { greet, thinking, cheer, idle }

/// The conversation: greets, asks for whatever is missing, shows the estimate,
/// then answers questions about it.
class EnergyChatController extends ChangeNotifier {
  static const suggestions = ['How did you work that out?', 'What\'s that in food?', 'Why a range?'];
  static const durationChoices = [30, 45, 60, 75, 90];

  final EnergyFacts facts;
  final EnergyResponder responder;
  final String botName;
  final Duration typingDelay;
  final EnergyAnalytics analytics;

  final List<EnergyMessage> messages = [];
  final Set<String> _asked = {};
  EnergyQuestion waitingFor = EnergyQuestion.none;
  EnergyEstimate? estimate;
  bool typing = false;
  BotMood mood = BotMood.greet;

  double? _weightKg;
  int? _minutes;
  bool _disposed = false;

  EnergyChatController({
    required this.facts,
    required this.responder,
    required this.botName,
    this.typingDelay = const Duration(milliseconds: 650),
    this.analytics = const EnergyAnalytics(),
  })  : _weightKg = facts.weightKg,
        _minutes = facts.session.minutes;

  /// Suggested questions not asked yet. None until there is a number to ask about.
  List<String> get openSuggestions =>
      estimate == null || typing ? const [] : [for (final s in suggestions) if (!_asked.contains(s)) s];

  Future<void> start() async {
    final sets = facts.session.sets;
    await _say(sets > 0
        ? 'Nice work! $sets ${sets == 1 ? 'set' : 'sets'} in the bag 💪'
        : 'Nice work finishing your workout 💪');
    await _next();
  }

  Future<void> _next() async {
    if (_minutes == null) {
      await _say('How long did you train, in minutes?', mood: BotMood.idle);
      _wait(EnergyQuestion.duration);
    } else if (_weightKg == null) {
      await _say('And what do you weigh, in ${facts.imperial ? 'lb' : 'kg'}?', mood: BotMood.idle);
      _wait(EnergyQuestion.weight);
    } else {
      await _say('Here\'s the energy you used:');
      if (_disposed) return;
      final s = facts.session;
      final result = EnergyEstimate.of(
        weightKg: _weightKg!,
        minutes: _minutes!,
        effort: EffortRating.of(sets: s.sets, minutes: _minutes!, bigLiftSets: s.bigLiftSets),
      );
      estimate = result;
      messages.add(EnergyResult(result));
      mood = BotMood.cheer;
      analytics.estimateShown(result.effort.level,
          askedDuration: s.minutes == null, askedWeight: facts.weightKg == null);
      notifyListeners();
    }
  }

  void _wait(EnergyQuestion q) {
    if (_disposed) return;
    waitingFor = q;
    notifyListeners();
  }

  Future<void> pickMinutes(int minutes) async {
    if (waitingFor != EnergyQuestion.duration || typing) return;
    messages.add(UserText('$minutes ${minutes == 1 ? 'minute' : 'minutes'}'));
    waitingFor = EnergyQuestion.none;
    if (minutes < 1 || minutes > 600) {
      await _say('That doesn\'t sound right. How many minutes was it?', mood: BotMood.idle);
      return _wait(EnergyQuestion.duration);
    }
    _minutes = minutes;
    await _next();
  }

  /// [value] is in the user's unit.
  Future<void> pickWeight(double value) async {
    if (waitingFor != EnergyQuestion.weight || typing) return;
    final unit = facts.imperial ? 'lb' : 'kg';
    final shown = value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    messages.add(UserText('$shown $unit'));
    waitingFor = EnergyQuestion.none;
    final kg = facts.imperial ? BodyUnits.lbToKg(value) : value;
    if (kg < 25 || kg > 350) {
      await _say('That doesn\'t sound right. What do you weigh in $unit?', mood: BotMood.idle);
      return _wait(EnergyQuestion.weight);
    }
    _weightKg = kg;
    await _next();
  }

  /// Text from the input box: an answer to the open question, or a new one.
  /// Returns false when it was not taken, so the box can keep it.
  bool send(String raw) {
    final text = raw.trim();
    if (text.isEmpty || typing) return false;
    if (waitingFor != EnergyQuestion.none) {
      final number = double.tryParse(
          RegExp(r'\d+(?:[.,]\d+)?').firstMatch(text)?.group(0)?.replaceAll(',', '.') ?? '');
      if (number == null) return false;
      if (waitingFor == EnergyQuestion.duration) {
        pickMinutes(number.round());
      } else {
        pickWeight(number);
      }
      return true;
    }
    final current = estimate;
    if (current == null) return false;
    _answer(text, current);
    return true;
  }

  Future<void> _answer(String text, EnergyEstimate current) async {
    final history = [
      for (final m in messages)
        switch (m) {
          BotText(:final text) => EnergyTurn(text),
          UserText(:final text) => EnergyTurn(text, fromUser: true),
          EnergyResult(:final estimate) =>
            EnergyTurn('Estimate shown: ${estimate.lowKcal} to ${estimate.highKcal} kcal.'),
        }
    ];
    final suggested = suggestions.contains(text);
    _asked.add(text);
    messages.add(UserText(text));
    mood = BotMood.thinking;
    typing = true;
    notifyListeners();
    analytics.questionAsked(suggested: suggested);

    final ask = EnergyAsk(
      question: text,
      botName: botName,
      session: facts.session,
      estimate: current,
      history: history,
    );
    EnergyReply reply;
    try {
      reply = await responder.reply(ask);
    } catch (_) {
      reply = EnergyReply.fallback(ask, EnergyError.server);
    }
    if (_disposed) return;
    analytics.answered(fromModel: reply.fromModel, error: reply.error);
    typing = false;
    mood = BotMood.idle;
    messages.add(BotText(reply.text,
        offline: reply.error == EnergyError.offline || reply.error == EnergyError.server));
    notifyListeners();
  }

  Future<void> _say(String text, {BotMood mood = BotMood.greet}) async {
    if (_disposed) return;
    typing = true;
    this.mood = BotMood.thinking;
    notifyListeners();
    await Future<void>.delayed(typingDelay);
    if (_disposed) return;
    typing = false;
    this.mood = mood;
    messages.add(BotText(text));
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
