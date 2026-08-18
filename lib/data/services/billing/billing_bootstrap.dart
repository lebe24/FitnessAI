import 'dart:async';

import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configures RevenueCat at launch and keeps it pointed at the signed-in user.
///
/// This exists because configuration used to happen in exactly one place — the
/// billing page. Any user who never opened Profile → Billing ran with an
/// unconfigured SDK, which is the worst possible state once features are
/// gated: `isPro` is false so everything locks, and the paywall that would
/// unlock it skips itself with "billing not configured". Locked out, with no
/// way to pay.
///
/// Entitlement is per-account, not per-device, so the SDK identity has to
/// track auth:
///
///  * signed in at launch  → configure with that user id
///  * signs in later       → log in, so their purchases follow them
///  * signs out            → log out, so the next user on the device does not
///                           inherit the previous one's Pro
class BillingBootstrap {
  final SubscriptionService _subs;
  final SupabaseClient _supabase;
  StreamSubscription<AuthState>? _authSub;

  BillingBootstrap({
    required SubscriptionService subs,
    required SupabaseClient supabase,
  })  : _subs = subs,
        _supabase = supabase;

  /// Safe to call once at startup, before or after sign-in.
  ///
  /// Never throws and never blocks launch: billing is not on the critical path
  /// for opening the app, and a network hiccup here must not stop it starting.
  Future<void> start() async {
    try {
      await _subs.init(_supabase.auth.currentUser?.id);
    } catch (e) {
      debugPrint('BillingBootstrap: initial configure failed — $e');
    }

    _authSub = _supabase.auth.onAuthStateChange.listen(
      (state) async {
        try {
          final userId = state.session?.user.id;
          switch (state.event) {
            case AuthChangeEvent.signedIn:
            case AuthChangeEvent.tokenRefreshed:
            case AuthChangeEvent.userUpdated:
              if (userId != null) await _subs.init(userId);
            case AuthChangeEvent.signedOut:
              await _subs.logOut();
            default:
              break;
          }
        } catch (e) {
          debugPrint('BillingBootstrap: auth change failed — $e');
        }
      },
      onError: (Object e) =>
          debugPrint('BillingBootstrap: auth stream error — $e'),
    );
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
  }
}
