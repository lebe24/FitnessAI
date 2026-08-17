import 'dart:async';

import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/billing/paywall_service.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kLime = Color(0xFFCCFF00);

/// Runs [onGranted] if the user may use [feature], otherwise opens the paywall.
///
/// This is the only sanctioned way to enter a gated feature. Call it in place
/// of the action it guards:
///
/// ```dart
/// onTap: () => requirePremium(
///   context,
///   PremiumFeature.nutritionScanner,
///   () => context.push(ScreenPaths.nutrition),
/// ),
/// ```
///
/// If the purchase succeeds the action runs immediately — the user asked for
/// the feature, paid for it, and should land in it rather than being returned
/// to where they started to tap again.
Future<void> requirePremium(
  BuildContext context,
  PremiumFeature feature,
  FutureOr<void> Function() onGranted,
) async {
  final access = sl<AccessPolicy>();

  if (access.canUse(feature)) {
    await onGranted();
    return;
  }

  final purchased = await sl<PaywallService>().present();
  if (purchased && context.mounted) {
    await onGranted();
  }
}

/// Small lock chip laid over a feature the user cannot use yet.
///
/// The gate is soft by design: the feature stays visible and tappable, and
/// tapping explains the offer. Hiding it would mean nobody discovers what a
/// subscription buys, and the app would appear to lose features overnight when
/// a trial lapses.
class PremiumBadge extends StatelessWidget {
  /// Hidden entirely once the user has access, so the chip does not linger
  /// over something they have already paid for.
  final bool visible;
  final String label;

  const PremiumBadge({
    super.key,
    required this.visible,
    this.label = 'PRO',
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _kLime.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kLime.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 9, color: _kLime),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: _kLime,
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience for the common "icon tile with a lock in the corner" layout.
class PremiumOverlay extends StatelessWidget {
  final Widget child;
  final bool locked;

  const PremiumOverlay({
    super.key,
    required this.child,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Dimmed rather than hidden — still legible, clearly not yet yours.
        Opacity(opacity: 0.55, child: child),
        Positioned(
          top: -4,
          right: -4,
          child: const PremiumBadge(visible: true),
        ),
      ],
    );
  }
}
