import 'dart:async';

import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_service.dart';
import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Starts analytics at launch and keeps it pointed at the signed-in user,
/// following the same pattern as `BillingBootstrap`.
///
///  * signed in at launch → identify with that user id
///  * signs in later      → identify, so earlier anonymous events join them
///  * signs out           → reset, so the next person on the device is not
///                          recorded as the previous one
///
/// It also records screen views by watching the router, and tags every event
/// with the subscription tier so funnels can be split free / trial / paid.
///
/// Never throws and never delays launch: a failure here leaves the app running
/// with analytics off, which is the right way to fail.
class AnalyticsBootstrap {
  final AnalyticsService _analytics;
  final SupabaseClient _supabase;
  final AccessPolicy _access;
  final GoRouter _router;

  StreamSubscription<AuthState>? _authSub;
  String? _lastScreen;

  AnalyticsBootstrap({
    required AnalyticsService analytics,
    required SupabaseClient supabase,
    required AccessPolicy access,
    required GoRouter router,
  })  : _analytics = analytics,
        _supabase = supabase,
        _access = access,
        _router = router;

  Future<void> start() async {
    try {
      await _analytics.init();
    } catch (e) {
      debugPrint('AnalyticsBootstrap: init failed, analytics off — $e');
      return;
    }
    Analytics.use(_analytics);

    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) Analytics.identify(userId);

    _applyTier();
    _access.addListener(_applyTier);

    _router.routerDelegate.addListener(_onRouteChanged);
    _onRouteChanged();

    _authSub = _supabase.auth.onAuthStateChange.listen(
      (state) {
        final id = state.session?.user.id;
        switch (state.event) {
          case AuthChangeEvent.signedIn:
            if (id != null) Analytics.identify(id);
          case AuthChangeEvent.signedOut:
            Analytics.reset();
          default:
            break;
        }
      },
      onError: (Object e) =>
          debugPrint('AnalyticsBootstrap: auth stream error — $e'),
    );
  }

  void _applyTier() =>
      Analytics.setSuperProperty('access_tier', _access.tier.name);

  void _onRouteChanged() {
    try {
      final path = _router.routerDelegate.currentConfiguration.uri.path;
      final name = screenNameFor(path);
      if (name == _lastScreen) return;
      _lastScreen = name;
      Analytics.screen(name);
    } catch (e) {
      debugPrint('AnalyticsBootstrap: route read failed — $e');
    }
  }

  /// `/workout-plan-detail` → `workout-plan-detail`; the root route is the
  /// splash screen. Only the path is used, so no query value (which could
  /// carry user content) is ever sent.
  @visibleForTesting
  static String screenNameFor(String path) {
    final trimmed = path.startsWith('/') ? path.substring(1) : path;
    return trimmed.isEmpty ? 'splash' : trimmed;
  }

  Future<void> dispose() async {
    _access.removeListener(_applyTier);
    _router.routerDelegate.removeListener(_onRouteChanged);
    await _authSub?.cancel();
    _authSub = null;
  }
}
