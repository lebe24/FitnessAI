import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A single AI-written motivational notification.
class MotivationMessage {
  final String title;
  final String body;
  const MotivationMessage({required this.title, required this.body});

  factory MotivationMessage.fromJson(Map<String, dynamic> j) => MotivationMessage(
        title: j['title'] as String? ?? 'Time to train',
        body: j['body'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'title': title, 'body': body};
}

/// Schedules the daily motivational notification.
///
/// Messages are AI-generated server-side (POST /api/v1/motivation/notifications)
/// and scheduled **locally**, so delivery keeps working with no network and
/// needs no push infrastructure. One backend call covers a week.
class MotivationNotificationService {
  static const int _baseId = 8100; // reserved id range for motivation
  static const String _channelId = 'befit_motivation';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    // Local wall-clock scheduling needs the device zone; fall back to UTC
    // rather than throwing if it can't be resolved.
    try {
      tz.setLocalLocation(tz.getLocation(await _deviceTimeZone()));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false, // asked explicitly in requestPermission()
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ));
    _ready = true;
  }

  Future<String> _deviceTimeZone() async {
    // timezone has no device-zone lookup; derive it from the current offset.
    final offset = DateTime.now().timeZoneOffset;
    for (final name in tz.timeZoneDatabase.locations.keys) {
      final loc = tz.getLocation(name);
      if (loc.currentTimeZone.offset == offset.inMilliseconds) return name;
    }
    return 'UTC';
  }

  /// Ask the OS for permission. Returns false if the user declined.
  Future<bool> requestPermission() async {
    await init();
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Motivation',
          channelDescription: 'Daily AI motivation in your chosen tone',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Schedule one notification per day at [hour]:[minute], walking through
  /// [messages] — day 1 gets the first message, day 2 the second, and so on.
  ///
  /// Replaces any previously scheduled motivation notifications.
  Future<void> scheduleDaily({
    required List<MotivationMessage> messages,
    required int hour,
    required int minute,
  }) async {
    await init();
    await cancelAll();
    if (messages.isEmpty) return;

    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final when = _nextInstanceOf(hour, minute).add(Duration(days: i));
      try {
        await _plugin.zonedSchedule(
          _baseId + i,
          m.title,
          m.body,
          when,
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: null, // one-shot per message, not repeating
        );
      } catch (e) {
        debugPrint('Motivation schedule failed for day $i: $e');
      }
    }
  }

  /// The next occurrence of the given wall-clock time, today if it hasn't
  /// passed yet, otherwise tomorrow.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancelAll() async {
    await init();
    // Only clear our own id range — other features may schedule notifications.
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _baseId && p.id < _baseId + 100) {
        await _plugin.cancel(p.id);
      }
    }
  }

  /// How many motivation notifications are still queued — used to decide when
  /// to refill from the backend.
  Future<int> pendingCount() async {
    await init();
    final pending = await _plugin.pendingNotificationRequests();
    return pending
        .where((p) => p.id >= _baseId && p.id < _baseId + 100)
        .length;
  }
}
