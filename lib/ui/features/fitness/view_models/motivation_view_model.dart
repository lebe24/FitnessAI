import 'package:fitness/data/services/motivation/motivation_notification_service.dart';
import 'package:fitness/data/services/motivation/motivation_remote_service.dart';
import 'package:fitness/data/services/motivation/motivation_schedule_storage.dart';
import 'package:flutter/foundation.dart';

/// Outcome of arming the daily motivation, so the UI can say something useful.
enum MotivationSetupResult { success, permissionDenied, noMessages }

/// Owns the motivation reminder flow: fetch AI copy for the chosen tone, then
/// schedule it locally at the chosen time.
class MotivationViewModel extends ChangeNotifier {
  final MotivationRemoteService _remote;
  final MotivationNotificationService _notifications;

  MotivationViewModel({
    required MotivationRemoteService remote,
    required MotivationNotificationService notifications,
  })  : _remote = remote,
        _notifications = notifications;

  MotivationSchedule? _schedule;
  bool _busy = false;

  MotivationSchedule? get schedule => _schedule;
  bool get busy => _busy;
  bool get isEnabled => _schedule != null;

  Future<void> load() async {
    _schedule = await MotivationScheduleStorage.load();
    notifyListeners();
    // Top up if the queue has drained (each fetch covers ~a week).
    if (_schedule != null && await _notifications.pendingCount() <= 1) {
      await _refill(_schedule!);
    }
  }

  /// Turn on daily motivation for [tone] at the given slot.
  Future<MotivationSetupResult> enable({
    required String tone,
    required MotivationSlot slot,
    int? hour,
    int? minute,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      if (!await _notifications.requestPermission()) {
        return MotivationSetupResult.permissionDenied;
      }
      final schedule = MotivationSchedule.forSlot(tone, slot,
          hour: hour, minute: minute);
      final messages = await _remote.fetchMessages(
        tone: tone,
        schedule: schedule.scheduleLabel,
      );
      if (messages.isEmpty) return MotivationSetupResult.noMessages;

      await _notifications.scheduleDaily(
        messages: messages,
        hour: schedule.hour,
        minute: schedule.minute,
      );
      _schedule = MotivationSchedule(
        tone: schedule.tone,
        slot: schedule.slot,
        hour: schedule.hour,
        minute: schedule.minute,
        lastFetched: DateTime.now(),
      );
      await MotivationScheduleStorage.save(_schedule!);
      return MotivationSetupResult.success;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Write one message in [tone] to show immediately, from the user's profile.
  ///
  /// Kept separate from [enable]: this asks for nothing, schedules nothing and
  /// needs no notification permission — it just returns copy to render inline.
  /// Null means the request failed and the caller should offer a retry.
  Future<MotivationMessage?> motivateNow(String tone) async {
    _busy = true;
    notifyListeners();
    try {
      return await _remote.fetchOne(tone: tone);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> disable() async {
    await _notifications.cancelAll();
    await MotivationScheduleStorage.clear();
    _schedule = null;
    notifyListeners();
  }

  /// Fetch a fresh batch for an existing schedule — keeps the copy from
  /// repeating week to week.
  Future<void> _refill(MotivationSchedule s) async {
    final messages = await _remote.fetchMessages(
      tone: s.tone,
      schedule: s.scheduleLabel,
    );
    if (messages.isEmpty) return;
    await _notifications.scheduleDaily(
      messages: messages,
      hour: s.hour,
      minute: s.minute,
    );
    _schedule = MotivationSchedule(
      tone: s.tone, slot: s.slot, hour: s.hour, minute: s.minute,
      lastFetched: DateTime.now(),
    );
    await MotivationScheduleStorage.save(_schedule!);
    notifyListeners();
  }
}
