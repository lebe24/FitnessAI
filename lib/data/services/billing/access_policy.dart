import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:flutter/foundation.dart';

/// Where the user stands with us.
enum AccessTier {
  /// Never subscribed, or the subscription has lapsed.
  free,

  /// Inside Apple's introductory free trial. Full access; Apple converts this
  /// to [paid] automatically unless the user cancels first.
  trial,

  /// Paying.
  paid,
}

/// The single question the app asks before opening a premium feature.
///
/// Deliberately thin: it does not fetch, cache or decide anything about
/// entitlement itself. [SubscriptionService] owns that, sourced from
/// RevenueCat, which is in turn sourced from Apple. Adding a second place that
/// reasons about access is how apps end up unlocking features for people who
/// have not paid — so this class only maps an already-known entitlement onto a
/// feature list.
///
/// The trial needs no code of its own. Apple's introductory offer keeps the
/// entitlement *active* for its whole duration, so a trialling user is simply
/// a user with `isPro == true`. The distinction between [AccessTier.trial] and
/// [AccessTier.paid] exists for what we *say* to the user ("4 days left"),
/// never for what we let them do.
class AccessPolicy extends ChangeNotifier {
  final SubscriptionService _subs;

  AccessPolicy(this._subs) {
    // Re-emit so widgets can watch access without also knowing about billing.
    _subs.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _subs.removeListener(notifyListeners);
    super.dispose();
  }

  AccessTier get tier {
    if (!_subs.isPro) return AccessTier.free;
    return _subs.isInTrial ? AccessTier.trial : AccessTier.paid;
  }

  bool get isFree => tier == AccessTier.free;
  bool get isTrialling => tier == AccessTier.trial;
  bool get isPaying => tier == AccessTier.paid;

  /// Whether [feature] is available right now.
  ///
  /// Every gated entry point calls this. The switch is exhaustive on purpose:
  /// adding a case to [PremiumFeature] fails compilation here until someone
  /// decides which side of the paywall it belongs on.
  bool canUse(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.nutritionScanner:
      case PremiumFeature.bodyComposition:
      case PremiumFeature.motivation:
      case PremiumFeature.agentChat:
      case PremiumFeature.equipmentScan:
      case PremiumFeature.videoTutorial:
        return _subs.isPro;
    }
  }

  /// When the current trial or period ends. Null when the user has never
  /// subscribed, or while entitlement state has not loaded yet.
  DateTime? get periodEndsAt => _subs.expirationDate;

  /// Whole days left in the current period, floored, never negative.
  ///
  /// Used only for messaging. Access is decided by [canUse], never by this —
  /// the device clock is not trustworthy, and Apple has already made the real
  /// decision by the time we see the entitlement.
  int? get daysRemaining {
    final end = periodEndsAt;
    if (end == null) return null;
    final left = end.difference(DateTime.now()).inDays;
    return left < 0 ? 0 : left;
  }

  /// True while a trial is close enough to its end to be worth mentioning.
  bool get trialEndingSoon {
    if (!isTrialling) return false;
    final days = daysRemaining;
    return days != null && days <= 2;
  }

  /// One line describing the user's standing, for the profile and billing
  /// screens. Null when there is nothing worth saying.
  String? get statusLabel {
    switch (tier) {
      case AccessTier.free:
        return null;
      case AccessTier.trial:
        final days = daysRemaining;
        if (days == null) return 'Free trial';
        if (days == 0) return 'Trial ends today';
        return 'Free trial · $days ${days == 1 ? 'day' : 'days'} left';
      case AccessTier.paid:
        // Someone who has cancelled keeps access to the end of the period;
        // saying "renews" then would be wrong.
        return _subs.willRenew ? 'Pro · active' : 'Pro · ends soon';
    }
  }
}
