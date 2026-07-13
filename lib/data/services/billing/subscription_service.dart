import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat entitlement id that unlocks all premium features.
const kPremiumEntitlement = 'premium';

/// Wraps the RevenueCat SDK: configuration, offerings, purchase, restore,
/// and a listenable premium flag.
///
/// Degrades gracefully when `REVENUECAT_IOS_API_KEY` is missing from .env —
/// [isConfigured] stays false and the billing UI falls back to its
/// "coming soon" behaviour, so the app never crashes on an unconfigured build.
///
/// The backend learns about entitlement changes independently via the
/// RevenueCat webhook (`POST /api/v1/billing/webhook`) — this service only
/// drives the client UI.
class SubscriptionService extends ChangeNotifier {
  bool _configured = false;
  bool _premium = false;
  Offerings? _offerings;

  bool get isConfigured => _configured;
  bool get isPremium => _premium;
  Offerings? get offerings => _offerings;

  /// Configure the SDK identified by the Supabase auth UUID so entitlements
  /// follow the account (and the backend webhook can map `app_user_id` to a
  /// `user_profiles` row). Safe to call repeatedly.
  Future<void> init(String? supabaseUserId) async {
    if (_configured) {
      // Already configured — just make sure the identity is current.
      if (supabaseUserId != null && supabaseUserId.isNotEmpty) {
        await _logInIfNeeded(supabaseUserId);
      }
      return;
    }

    final apiKey = Platform.isIOS
        ? dotenv.env['REVENUECAT_IOS_API_KEY']
        : dotenv.env['REVENUECAT_ANDROID_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('SubscriptionService: no RevenueCat API key in .env — billing disabled');
      return;
    }

    try {
      final config = PurchasesConfiguration(apiKey);
      if (supabaseUserId != null && supabaseUserId.isNotEmpty) {
        config.appUserID = supabaseUserId;
      }
      await Purchases.configure(config);
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
      _configured = true;
      await refresh();
    } catch (e) {
      debugPrint('SubscriptionService: configure failed — $e');
    }
  }

  Future<void> _logInIfNeeded(String userId) async {
    try {
      final current = await Purchases.appUserID;
      if (current != userId) {
        final result = await Purchases.logIn(userId);
        _onCustomerInfo(result.customerInfo);
      }
    } catch (e) {
      debugPrint('SubscriptionService: logIn failed — $e');
    }
  }

  void _onCustomerInfo(CustomerInfo info) {
    final active = info.entitlements.active.containsKey(kPremiumEntitlement);
    if (active != _premium) {
      _premium = active;
      notifyListeners();
    }
  }

  /// Re-read entitlements and offerings from RevenueCat.
  Future<void> refresh() async {
    if (!_configured) return;
    try {
      _onCustomerInfo(await Purchases.getCustomerInfo());
      _offerings = await Purchases.getOfferings();
      notifyListeners();
    } catch (e) {
      debugPrint('SubscriptionService: refresh failed — $e');
    }
  }

  /// The current offering's monthly / yearly packages (null until loaded).
  Package? get monthly => _offerings?.current?.monthly;
  Package? get yearly => _offerings?.current?.annual;

  /// Launch the StoreKit purchase flow. Returns true when premium is active
  /// afterwards. A user cancel returns false without surfacing an error.
  Future<bool> purchase(Package package) async {
    if (!_configured) return false;
    try {
      final info = await Purchases.purchasePackage(package);
      _onCustomerInfo(info);
      return _premium;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return false; // user backed out of the payment sheet — not an error
      }
      debugPrint('SubscriptionService: purchase failed — $e');
      rethrow;
    }
  }

  /// Restore previous purchases (required by Apple on any paywall).
  Future<bool> restore() async {
    if (!_configured) return false;
    try {
      _onCustomerInfo(await Purchases.restorePurchases());
      return _premium;
    } catch (e) {
      debugPrint('SubscriptionService: restore failed — $e');
      return false;
    }
  }
}
