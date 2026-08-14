import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Writes the technical half of a failure to Supabase `error_logs`.
///
/// The user sees a [FriendlyError]; everything needed to actually debug the
/// problem — exception type, message, stack, where it happened — comes here.
///
/// Three rules this class must never break:
///
///  * **It never throws.** It is called from inside `catch` blocks. An error
///    reporter that fails while reporting an error would replace a handled
///    problem with an unhandled one.
///  * **It never blocks the UI.** Callers do not await it; the user gets their
///    message immediately whether or not the log write succeeds.
///  * **It never logs credentials.** Payloads are passed explicitly by the
///    caller, so nothing is captured by accident.
class ErrorLogService {
  static const String _table = 'error_logs';

  /// Cached so we do not hit the platform channel on every failure.
  static String? _appVersion;

  /// Record [error] against [area]/[action].
  ///
  /// Fire-and-forget by design — call it without `await`:
  ///
  /// ```dart
  /// ErrorLogService.report(
  ///   area: 'onboarding.auth',
  ///   action: 'sign_in_google',
  ///   error: e,
  ///   stackTrace: st,
  /// );
  /// ```
  static Future<void> report({
    required String area,
    required String action,
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    // Always visible locally, even when the remote write is impossible.
    debugPrint('[$area/$action] $error');

    try {
      final client = Supabase.instance.client;

      await client.from(_table).insert({
        // Null before sign-in, which covers most of onboarding.
        'user_id': client.auth.currentUser?.id,
        'area': area,
        'action': action,
        'error_type': error.runtimeType.toString(),
        'message': _truncate(error.toString(), 2000),
        // Stacks are long and only the top frames identify the fault.
        'stack_trace':
            stackTrace == null ? null : _truncate(stackTrace.toString(), 4000),
        'context': context,
        'app_version': await _version(),
        'platform': _platform(),
      });
    } catch (e) {
      // Swallowed on purpose. A failed log write must not surface anywhere
      // near the user, and must not mask the original error.
      debugPrint('ErrorLogService: could not write log — $e');
    }
  }

  static Future<String?> _version() async {
    if (_appVersion != null) return _appVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _appVersion = null;
    }
    return _appVersion;
  }

  static String _platform() {
    try {
      if (Platform.isIOS) return 'ios';
      if (Platform.isAndroid) return 'android';
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }

  static String _truncate(String value, int max) =>
      value.length <= max ? value : '${value.substring(0, max)}…[truncated]';
}
