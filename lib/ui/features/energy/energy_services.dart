import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/body/legacy_weight.dart';
import 'package:fitness/data/services/energy/energy_coach_service.dart';
import 'package:fitness/data/repositories/body_tracking_repository.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:fitness/ui/features/energy/view_models/bot_settings_controller.dart';
import 'package:flutter/widgets.dart';

/// What the energy bot needs from the rest of the app, in one place so screens
/// that show it can be given stand-ins.
class EnergyServices {
  final bool Function() allowed;

  /// Fires when access may have changed.
  final Listenable access;

  /// Offers Pro. True when the user now has access.
  final Future<bool> Function(BuildContext context) unlock;

  /// The latest logged body weight, or null when there is none.
  final Future<double?> Function() weightKg;
  final EnergyResponder responder;
  final BotSettingsController bot;

  const EnergyServices({
    required this.allowed,
    required this.access,
    required this.unlock,
    required this.weightKg,
    required this.responder,
    required this.bot,
  });

  /// Null where the app has not been set up, such as a screen shown on its own.
  static EnergyServices? fromLocator() {
    if (!sl.isRegistered<BotSettingsController>()) return null;
    final policy = sl<AccessPolicy>();
    return EnergyServices(
      allowed: () => policy.canUse(PremiumFeature.energyChat),
      access: policy,
      unlock: (context) async {
        var unlocked = false;
        await requirePremium(context, PremiumFeature.energyChat, () {
          unlocked = true;
        });
        return unlocked;
      },
      weightKg: () async {
        final logged = (await sl<BodyTrackingRepository>().load()).weights;
        return logged.isNotEmpty ? logged.last.weightKg : await LegacyWeight.readKg();
      },
      responder: sl<EnergyResponder>(),
      bot: sl<BotSettingsController>(),
    );
  }
}
