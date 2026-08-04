import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// Presents RevenueCat's hosted Paywall and Customer Center.
///
/// The paywall is designed in the RevenueCat dashboard rather than in code, so
/// pricing, copy, and layout can change without an App Store release. Apple's
/// required elements (restore button, auto-renewal terms, Terms/Privacy links)
/// are part of the dashboard template — configure them there.
class PaywallService {
  final SubscriptionService _subs;
  PaywallService(this._subs);

  /// Show the paywall unconditionally.
  ///
  /// Returns true if the user came out of it with Pro. Safe to call when
  /// billing isn't configured — it no-ops rather than throwing.
  Future<bool> present({String? offeringIdentifier}) async {
    if (!_subs.isConfigured) {
      debugPrint('PaywallService: billing not configured — paywall skipped');
      return false;
    }
    try {
      final offering = offeringIdentifier == null
          ? null
          : _subs.offerings?.all[offeringIdentifier];

      final result = offering != null
          ? await RevenueCatUI.presentPaywall(offering: offering)
          : await RevenueCatUI.presentPaywall();

      // The listener already updated state, but refresh so callers reading
      // isPro immediately after this returns see the settled value.
      await _subs.refresh();
      return _isPurchased(result);
    } catch (e) {
      debugPrint('PaywallService.present failed — $e');
      return false;
    }
  }

  /// Show the paywall **only if** the user lacks Pro — the recommended way to
  /// gate a premium feature, since it's a no-op for existing subscribers.
  ///
  /// Returns true when the user has Pro afterwards (already had it, or just
  /// bought it), so callers can proceed on true.
  Future<bool> presentIfNeeded() async {
    if (!_subs.isConfigured) return false;
    if (_subs.isPro) return true;
    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(kProEntitlement);
      await _subs.refresh();
      return _subs.isPro || _isPurchased(result);
    } catch (e) {
      debugPrint('PaywallService.presentIfNeeded failed — $e');
      return false;
    }
  }

  /// Gate a premium action: runs [onGranted] only once the user has Pro,
  /// showing the paywall first if they don't.
  Future<void> gate(BuildContext context, VoidCallback onGranted) async {
    if (await presentIfNeeded()) {
      if (context.mounted) onGranted();
    }
  }

  /// RevenueCat's self-service subscription management — cancel, refund
  /// requests, plan changes, and restore, all without leaving the app.
  ///
  /// Only worth showing to users who actually have a subscription; for
  /// everyone else it's an empty screen.
  Future<void> presentCustomerCenter() async {
    if (!_subs.isConfigured) return;
    try {
      await RevenueCatUI.presentCustomerCenter();
      // Plans may have changed while they were in there.
      await _subs.refresh();
    } catch (e) {
      debugPrint('PaywallService.presentCustomerCenter failed — $e');
    }
  }

  static bool _isPurchased(PaywallResult result) =>
      result == PaywallResult.purchased || result == PaywallResult.restored;
}
