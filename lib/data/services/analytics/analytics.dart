import 'dart:async';

import 'package:fitness/data/services/analytics/analytics_service.dart';
import 'package:flutter/foundation.dart';

/// The one-line way to record something from anywhere in the app:
///
/// ```dart
/// Analytics.track(AnalyticsEvents.workoutSaved, {'exercise_count': 5});
/// ```
///
/// Analytics must never be able to break the app, so every call here is
/// fire-and-forget and swallows its own errors. It is a static facade, not a
/// constructor dependency, because events are raised from dozens of places and
/// threading a service through all of them would touch every view model for no
/// gain. Tests swap the implementation with [use].
abstract final class Analytics {
  static AnalyticsService _service = NoopAnalyticsService();

  /// The active implementation. Set once at startup, replaced in tests.
  static void use(AnalyticsService service) => _service = service;

  static AnalyticsService get service => _service;

  static void track(String event, [Map<String, Object?>? properties]) =>
      _guard(() => _service.track(event, properties));

  static void screen(String name) => _guard(() => _service.screen(name));

  static void identify(String userId) =>
      _guard(() => _service.identify(userId));

  static void reset() => _guard(_service.reset);

  static void setSuperProperty(String key, Object value) =>
      _guard(() => _service.setSuperProperty(key, value));

  static void _guard(Future<void> Function() action) {
    try {
      unawaited(action().catchError((Object e) {
        debugPrint('Analytics: call failed — $e');
      }));
    } catch (e) {
      debugPrint('Analytics: call failed — $e');
    }
  }
}
