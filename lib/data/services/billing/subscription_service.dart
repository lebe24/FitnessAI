import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat entitlement that unlocks BeFit Pro.
///
/// This must match the entitlement **identifier** in the RevenueCat dashboard
/// (Project → Entitlements), not its display name. If the dashboard shows
/// "Fitness application Pro" as the display name, the identifier is the short
/// string beside it.
const String kProEntitlement = 'pro';

/// Product identifiers configured in App Store Connect and mapped to the
/// entitlement in RevenueCat.
class ProProducts {
  static const String monthly = 'monthly';
  static const String yearly = 'yearly';
  static const String lifetime = 'lifetime';
}

/// What went wrong on a purchase, in terms the UI can act on.
enum PurchaseOutcome {
  success,
  cancelled,        // user backed out — not an error, say nothing
  pending,          // deferred (e.g. Ask to Buy); entitlement may arrive later
  alreadyOwned,     // suggest Restore
  paymentDisabled,  // purchases restricted on the device
  networkError,
  storeError,
  notConfigured,    // no SDK key — billing is off in this build
}

/// Result of a purchase attempt: the outcome plus a message worth showing.
class PurchaseResult {
  final PurchaseOutcome outcome;
  final String? message;
  const PurchaseResult(this.outcome, [this.message]);

  bool get isSuccess => outcome == PurchaseOutcome.success;
  /// Cancellation is a normal user choice — don't surface it as a failure.
  bool get shouldShowMessage =>
      outcome != PurchaseOutcome.success && outcome != PurchaseOutcome.cancelled;
}

/// Wraps the RevenueCat SDK: configuration, offerings, purchase, restore, and
/// entitlement state.
///
/// Degrades to a no-op when `REVENUECAT_IOS_API_KEY` is absent from .env —
/// [isConfigured] stays false and the billing UI shows its "coming soon"
/// fallback, so an unconfigured build never crashes.
///
/// The backend learns about entitlement changes independently via the
/// RevenueCat webhook (`POST /api/v1/billing/webhook`); this service only
/// drives the client.
class SubscriptionService extends ChangeNotifier {
  bool _configured = false;
  bool _isPro = false;
  Offerings? _offerings;
  CustomerInfo? _customerInfo;

  bool get isConfigured => _configured;

  /// Whether the Pro entitlement is currently active.
  bool get isPro => _isPro;

  Offerings? get offerings => _offerings;
  CustomerInfo? get customerInfo => _customerInfo;

  // ── Configuration ──────────────────────────────────────────────────────────

  /// Configure the SDK, identified by the Supabase auth UUID so entitlements
  /// follow the account across devices and the backend webhook can map
  /// `app_user_id` to a `user_profiles` row. Safe to call repeatedly.
  Future<void> init(String? supabaseUserId) async {
    if (_configured) {
      if (supabaseUserId != null && supabaseUserId.isNotEmpty) {
        await _logInIfNeeded(supabaseUserId);
      }
      return;
    }

    final apiKey = Platform.isIOS
        ? dotenv.env['REVENUECAT_IOS_API_KEY']
        : dotenv.env['REVENUECAT_ANDROID_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('SubscriptionService: no RevenueCat API key — billing disabled');
      return;
    }

    try {
      // Verbose logs in debug only; they're noisy and leak product data.
      await Purchases.setLogLevel(
          kDebugMode ? LogLevel.debug : LogLevel.error);

      final config = PurchasesConfiguration(apiKey);
      if (supabaseUserId != null && supabaseUserId.isNotEmpty) {
        config.appUserID = supabaseUserId;
      }
      await Purchases.configure(config);

      // Fires on renewal, expiry, restore, and cross-device changes — the
      // single source of truth for entitlement state.
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
      _configured = true;
      await refresh();
    } catch (e) {
      debugPrint('SubscriptionService: configure failed — $e');
    }
  }

  Future<void> _logInIfNeeded(String userId) async {
    try {
      if (await Purchases.appUserID != userId) {
        final result = await Purchases.logIn(userId);
        _onCustomerInfo(result.customerInfo);
      }
    } catch (e) {
      debugPrint('SubscriptionService: logIn failed — $e');
    }
  }

  /// Call on sign-out so the next user doesn't inherit these entitlements.
  Future<void> logOut() async {
    if (!_configured) return;
    try {
      _onCustomerInfo(await Purchases.logOut());
    } catch (e) {
      debugPrint('SubscriptionService: logOut failed — $e');
    }
  }

  void _onCustomerInfo(CustomerInfo info) {
    _customerInfo = info;
    final active = info.entitlements.active.containsKey(kProEntitlement);
    if (active != _isPro) {
      _isPro = active;
    }
    notifyListeners();
  }

  /// True when the SDK is configured but the store returned no products.
  ///
  /// Normal during setup: it means the products aren't live in App Store
  /// Connect yet (or the Paid Apps agreement isn't active). Entitlements
  /// still work — only purchasing is unavailable.
  bool get productsUnavailable => _configured && _offerings?.current == null;

  /// Re-read entitlements and offerings.
  ///
  /// The two are fetched independently: offerings fail whenever products
  /// aren't configured yet, and that must not stop us reading entitlement
  /// state (a user can hold Pro via a promo or another platform even when
  /// this store has no products).
  Future<void> refresh() async {
    if (!_configured) return;

    try {
      _onCustomerInfo(await Purchases.getCustomerInfo());
    } catch (e) {
      debugPrint('SubscriptionService: customer info failed — $e');
    }

    try {
      _offerings = await Purchases.getOfferings();
      if (_offerings?.current == null) {
        debugPrint('SubscriptionService: no current offering — check that a '
            'default Offering exists in the RevenueCat dashboard.');
      }
    } on PlatformException catch (e) {
      // CONFIGURATION_ERROR is the expected state before products are live in
      // App Store Connect. Log one actionable line instead of the SDK's wall
      // of text on every refresh.
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.configurationError) {
        debugPrint('SubscriptionService: products not available yet — create '
            'them in App Store Connect, sign the Paid Apps agreement, and '
            'attach them to an Offering. Purchasing stays disabled until then.');
      } else {
        debugPrint('SubscriptionService: offerings failed — $e');
      }
    } catch (e) {
      debugPrint('SubscriptionService: offerings failed — $e');
    }

    notifyListeners();
  }

  // ── Packages ───────────────────────────────────────────────────────────────

  /// Every package in the current offering, in display order.
  List<Package> get availablePackages =>
      _offerings?.current?.availablePackages ?? const [];

  Package? get monthly => _offerings?.current?.monthly;
  Package? get yearly => _offerings?.current?.annual;

  /// Lifetime is a non-subscription purchase. Prefer the typed accessor, but
  /// fall back to matching the product id for custom-configured offerings.
  Package? get lifetime {
    final current = _offerings?.current;
    if (current == null) return null;
    return current.lifetime ??
        current.availablePackages
            .where((p) =>
                p.packageType == PackageType.lifetime ||
                p.storeProduct.identifier.contains(ProProducts.lifetime))
            .firstOrNull;
  }

  // ── Entitlement detail ─────────────────────────────────────────────────────

  EntitlementInfo? get _proEntitlement =>
      _customerInfo?.entitlements.active[kProEntitlement];

  /// When the current period ends. Null for lifetime purchases, which never
  /// expire — check [isLifetime] before showing a renewal date.
  DateTime? get expirationDate {
    final raw = _proEntitlement?.expirationDate;
    return raw == null ? null : DateTime.tryParse(raw);
  }

  bool get isLifetime =>
      _isPro && _proEntitlement?.expirationDate == null;

  /// True when the user cancelled but still has paid time remaining.
  bool get willRenew => _proEntitlement?.willRenew ?? false;

  /// e.g. "monthly" / "yearly" — which product granted the entitlement.
  String? get activeProductId => _proEntitlement?.productIdentifier;

  bool get isInTrial =>
      _proEntitlement?.periodType == PeriodType.trial;

  // ── Purchase ───────────────────────────────────────────────────────────────

  /// Launch the store purchase flow for [package].
  Future<PurchaseResult> purchase(Package package) async {
    if (!_configured) {
      return const PurchaseResult(
          PurchaseOutcome.notConfigured, 'Billing is not available yet.');
    }
    try {
      final info = await Purchases.purchasePackage(package);
      _onCustomerInfo(info);
      return _isPro
          ? const PurchaseResult(PurchaseOutcome.success)
          : const PurchaseResult(PurchaseOutcome.pending,
              'Purchase is processing — Pro unlocks once it completes.');
    } on PlatformException catch (e) {
      return _mapError(e);
    } catch (e) {
      debugPrint('SubscriptionService: purchase failed — $e');
      return const PurchaseResult(
          PurchaseOutcome.storeError, 'Purchase failed. You were not charged.');
    }
  }

  /// Translate a store error into something the UI can act on. Notably,
  /// cancellation is not treated as a failure.
  PurchaseResult _mapError(PlatformException e) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    switch (code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return const PurchaseResult(PurchaseOutcome.cancelled);
      case PurchasesErrorCode.paymentPendingError:
        return const PurchaseResult(PurchaseOutcome.pending,
            'Purchase pending approval — Pro unlocks once it clears.');
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return const PurchaseResult(PurchaseOutcome.alreadyOwned,
            'You already own this — tap Restore Purchases.');
      case PurchasesErrorCode.purchaseNotAllowedError:
      case PurchasesErrorCode.storeProblemError:
        return const PurchaseResult(PurchaseOutcome.paymentDisabled,
            'Purchases are not allowed on this device.');
      case PurchasesErrorCode.networkError:
        return const PurchaseResult(PurchaseOutcome.networkError,
            'Network problem — check your connection and try again.');
      default:
        debugPrint('SubscriptionService: purchase error $code — ${e.message}');
        return PurchaseResult(PurchaseOutcome.storeError,
            'Purchase failed. You were not charged.');
    }
  }

  /// Restore previous purchases. **Apple requires this on any paywall.**
  Future<bool> restore() async {
    if (!_configured) return false;
    try {
      _onCustomerInfo(await Purchases.restorePurchases());
      return _isPro;
    } catch (e) {
      debugPrint('SubscriptionService: restore failed — $e');
      return false;
    }
  }
}
