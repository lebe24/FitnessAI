import 'dart:async';

import 'package:fitness/data/services/analytics/analytics_events.dart';
import 'package:fitness/data/services/analytics/analytics_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// What the rest of the app can ask of analytics. Everything else about the
/// vendor stays behind this interface, so the SDK can be swapped, or replaced
/// by [NoopAnalyticsService] in tests, without touching a call site.
abstract class AnalyticsService {
  /// True when events are actually being collected.
  bool get enabled;

  Future<void> init();

  /// Tie later events to this user. The id is the Supabase user id — nothing
  /// else about the person is sent.
  Future<void> identify(String userId);

  /// Forget the current user, e.g. on sign-out, so the next person on the
  /// device does not inherit their history.
  Future<void> reset();

  Future<void> track(String event, [Map<String, Object?>? properties]);

  Future<void> screen(String name);

  /// Attach a property to every later event (e.g. the subscription tier).
  Future<void> setSuperProperty(String key, Object value);

  /// Apply and remember the user's choice.
  Future<void> setEnabled(bool enabled);
}

/// Collects nothing. Used when there is no API key (local development, tests)
/// or while the SDK has not started, so call sites never have to check.
class NoopAnalyticsService implements AnalyticsService {
  @override
  bool get enabled => false;
  @override
  Future<void> init() async {}
  @override
  Future<void> identify(String userId) async {}
  @override
  Future<void> reset() async {}
  @override
  Future<void> track(String event, [Map<String, Object?>? properties]) async {}
  @override
  Future<void> screen(String name) async {}
  @override
  Future<void> setSuperProperty(String key, Object value) async {}
  @override
  Future<void> setEnabled(bool enabled) async {}
}

/// PostHog-backed analytics.
///
/// Configured conservatively: only the events this app names are sent. Session
/// replay is off (the app shows physique and meal photos), surveys are off (no
/// pop-ups the app did not design), and push-token capture is off (the app only
/// uses local notifications).
class PostHogAnalyticsService implements AnalyticsService {
  final String apiKey;
  final String host;
  bool _enabled = false;

  PostHogAnalyticsService({required this.apiKey, required this.host});

  @override
  bool get enabled => _enabled;

  @override
  Future<void> init() async {
    final allowed = await AnalyticsPreferences.isEnabled();

    final config = PostHogConfig(apiKey)
      ..host = host
      ..optOut = !allowed
      ..debug = kDebugMode
      ..sessionReplay = false
      ..surveys = false
      ..captureApplicationLifecycleEvents = true
      ..capturePushNotificationSubscriptions = false
      ..capturePushNotificationOpened = false
      // Person profiles are created only for identified (signed-in) users.
      ..personProfiles = PostHogPersonProfiles.identifiedOnly;

    await Posthog().setup(config);
    _enabled = allowed;
  }

  @override
  Future<void> identify(String userId) async {
    if (!_enabled) return;
    await Posthog().identify(userId: userId);
  }

  @override
  Future<void> reset() async {
    if (!_enabled) return;
    await Posthog().reset();
  }

  @override
  Future<void> track(String event, [Map<String, Object?>? properties]) async {
    if (!_enabled) return;
    await Posthog().capture(
      eventName: event,
      properties: AnalyticsSanitizer.clean(properties),
    );
  }

  @override
  Future<void> screen(String name) async {
    if (!_enabled) return;
    await Posthog().screen(screenName: name);
  }

  @override
  Future<void> setSuperProperty(String key, Object value) async {
    if (!_enabled) return;
    await Posthog().register(key, value);
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (!enabled && _enabled) {
      // Record the opt-out while collection is still allowed, then stop.
      await Posthog().capture(eventName: AnalyticsEvents.analyticsOptedOut);
      await Posthog().flush();
    }
    await AnalyticsPreferences.setEnabled(enabled);
    if (enabled) {
      await Posthog().optIn();
    } else {
      await Posthog().optOut();
    }
    _enabled = enabled;
  }
}
