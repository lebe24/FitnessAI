import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_events.dart';
import 'package:fitness/data/services/energy/energy_coach_service.dart';
import 'package:fitness/domain/energy/bot_settings.dart';
import 'package:fitness/domain/energy/energy_effort.dart';

/// How the energy bot is used. Never what was asked, the bot's name, body
/// weight or a calorie figure: only that something happened, and fixed labels.
class EnergyAnalytics {
  const EnergyAnalytics();

  /// [source] is `session` or `finished`.
  void opened(String source) =>
      Analytics.track(AnalyticsEvents.energyChatOpened, {'source': source});

  void lockedTapped() => Analytics.track(AnalyticsEvents.energyLockedTapped);

  void finishPrompt({required bool accepted}) => Analytics.track(
      AnalyticsEvents.energyFinishPrompt, {'choice': accepted ? 'see' : 'not_now'});

  void estimateShown(EffortLevel effort, {required bool askedDuration, required bool askedWeight}) =>
      Analytics.track(AnalyticsEvents.energyEstimateShown, {
        'effort': effort.name,
        'asked_duration': askedDuration,
        'asked_weight': askedWeight,
      });

  void questionAsked({required bool suggested}) =>
      Analytics.track(AnalyticsEvents.energyQuestionAsked, {'suggested': suggested});

  void answered({required bool fromModel, EnergyError? error}) {
    if (error != null) {
      Analytics.track(AnalyticsEvents.energyAnswerFailed, {'reason': error.name});
    } else {
      Analytics.track(AnalyticsEvents.energyAnswerReceived, {'from_model': fromModel});
    }
  }

  void customised(BotSettings settings) => Analytics.track(AnalyticsEvents.energyBotCustomised, {
        'mascot': settings.mascot.name,
        'renamed': settings.name != BotSettings.defaultName,
      });
}
