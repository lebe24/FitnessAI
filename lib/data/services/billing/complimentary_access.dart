import 'package:fitness/data/services/billing/billing_remote_service.dart';
import 'package:flutter/foundation.dart';

/// Access the backend has granted us, rather than access the user bought.
///
/// Exists for App Review demo accounts, comped users and support goodwill.
/// The reviewer signs in with ordinary email credentials and everything is
/// simply open — no purchase, no sandbox Apple Account, and no RevenueCat
/// dashboard grant that someone has to remember to make and later revoke.
///
/// Three properties this deliberately has:
///
///  * **It only ever grants.** [isGranted] starts false and can only be turned
///    on by a successful response. An unreachable backend, a 500, a cold start
///    — none of them can take access away from a paying user, because
///    entitlement still comes from RevenueCat and this is OR'd with it.
///  * **It is not how anyone buys.** Real purchases flow through StoreKit and
///    RevenueCat. This is a manual flag on one row, set by us.
///  * **It survives subscription events.** The backing column is never written
///    by the RevenueCat webhook, so a reviewer's access cannot vanish partway
///    through review because some unrelated event fired.
class ComplimentaryAccess extends ChangeNotifier {
  /// Optional so the class can exist without a backend — in tests, and in any
  /// build where the API is unreachable. A missing backend means "no grant to
  /// check", never "access revoked".
  final BillingRemoteService? _remote;

  ComplimentaryAccess([this._remote]);

  bool _granted = false;
  bool _checked = false;

  /// Whether the backend has granted this account free access.
  bool get isGranted => _granted;

  /// False until the first successful check. Lets the UI tell "not granted"
  /// apart from "we have not looked yet".
  bool get hasChecked => _checked;

  /// Ask the backend. Safe to call repeatedly; never throws.
  ///
  /// Not awaited by anything on the critical path — the app must open, and
  /// gates must answer, whether or not this has completed.
  Future<void> refresh() async {
    final remote = _remote;
    if (remote == null) return;
    try {
      final status = await remote.getStatus();
      if (status == null) return; // unknown, not "revoked"
      _checked = true;
      if (status.isComplimentary != _granted) {
        _granted = status.isComplimentary;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ComplimentaryAccess: refresh failed — $e');
    }
  }

  /// Clear on sign-out so the next account on the device does not inherit it.
  void reset() {
    if (!_granted && !_checked) return;
    _granted = false;
    _checked = false;
    notifyListeners();
  }
}
