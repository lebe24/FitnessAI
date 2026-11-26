import 'package:fitness/data/services/body/body_tracking_remote.dart';
import 'package:fitness/data/services/body/body_tracking_store.dart';
import 'package:fitness/domain/body/body_advice.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:flutter/foundation.dart';

/// The user's goal, weigh-ins and measurements.
///
/// The server is the record; the device keeps a copy so screens open at once
/// and nothing typed offline is lost. A write is applied to the copy first. If
/// the server takes it, the copy gets the server's version (with its id). If
/// not, it waits in a pending list and goes up on the next [refresh].
class BodyTrackingRepository {
  final BodyTrackingRemote _remote;
  final BodyTrackingStore _store;
  final DateTime Function() _now;

  /// The single weight the app used to keep, in kg, or null. Read once to
  /// start the log so existing users do not begin from nothing.
  final Future<double?> Function() _legacyWeightKg;

  /// The signed-in user's id, or null when it cannot be known.
  final String? Function() _userId;

  BodyTrackingRepository({
    required BodyTrackingRemote remote,
    required BodyTrackingStore store,
    Future<double?> Function()? legacyWeightKg,
    String? Function()? currentUserId,
    DateTime Function()? now,
  })  : _remote = remote,
        _store = store,
        _legacyWeightKg = legacyWeightKg ?? (() async => null),
        _userId = currentUserId ?? (() => null),
        _now = now ?? DateTime.now;

  /// How far back the app reads. Older entries stay on the server.
  static const _historyDays = 400;

  /// What is on the device right now, for the signed-in user. A copy kept by a
  /// different account is dropped, with its advice, rather than shown or sent.
  Future<BodySnapshot> load() async {
    final s = await _store.load();
    final uid = _userId();
    if (uid == null) return s;
    if (s.ownerId == uid) return s;
    if (s.ownerId == null) {
      // First use on this device: from now on the copy is this account's.
      final owned = s.copyWith(ownerId: uid);
      await _store.save(owned);
      return owned;
    }
    await _store.clearAdvice();
    final fresh = BodySnapshot(ownerId: uid);
    await _store.save(fresh);
    return fresh;
  }

  Future<BodyAdvice?> cachedAdvice() async {
    await load(); // drops another account's advice first
    return _store.loadAdvice();
  }

  /// Sends anything waiting, then reads the server's copy. Throws a
  /// [BodyTrackingException] if the server cannot be reached; the device copy
  /// is left as it was.
  Future<BodySnapshot> refresh() async {
    var s = await load();

    if (s.goalPending && s.goal != null) {
      await _remote.putGoal(s.goal!);
    }
    if (s.pendingWeights.isNotEmpty || s.pendingMeasurements.isNotEmpty) {
      await _remote.sync(weights: s.pendingWeights, measurements: s.pendingMeasurements);
    }

    final since = _now().subtract(const Duration(days: _historyDays));
    final goal = await _remote.getGoal();
    final weights = await _remote.listWeights(since: since);
    final measurements = await _remote.listMeasurements(since: since);

    s = BodySnapshot(
      goal: goal,
      weights: _ascending(weights),
      measurements: _ascendingM(measurements),
      legacySeeded: s.legacySeeded,
      ownerId: s.ownerId,
    );

    if (!s.legacySeeded) {
      s = await _seedFromLegacy(s);
    }
    await _store.save(s);
    return s;
  }

  Future<BodySnapshot> _seedFromLegacy(BodySnapshot s) async {
    if (s.weights.isNotEmpty) return s.copyWith(legacySeeded: true);
    final kg = await _legacyWeightKg();
    if (kg == null || kg < 20 || kg > 400) return s.copyWith(legacySeeded: true);

    final entry = BodyWeightEntry(date: _now(), weightKg: kg, note: 'From your profile');
    try {
      final saved = await _remote.postWeight(entry);
      return s.copyWith(weights: [saved], legacySeeded: true);
    } on BodyTrackingException {
      return s.copyWith(weights: [entry], pendingWeights: [entry], legacySeeded: true);
    }
  }

  // ── Weight ─────────────────────────────────────────────────────────────────

  Future<BodySnapshot> logWeight(BodyWeightEntry entry) async {
    var s = await load();
    s = s.copyWith(weights: _ascending(_replaceDay(s.weights, entry)));
    try {
      final saved = await _remote.postWeight(entry);
      s = s.copyWith(
        weights: _ascending(_replaceDay(s.weights, saved)),
        pendingWeights: [for (final p in s.pendingWeights) if (p.date != entry.date) p],
      );
    } on BodyTrackingException catch (e) {
      debugPrint('BodyTracking: weight kept for later — $e');
      s = s.copyWith(pendingWeights: _replaceDay(s.pendingWeights, entry));
    }
    await _store.save(s);
    return s;
  }

  Future<BodySnapshot> deleteWeight(BodyWeightEntry entry) async {
    var s = await load();
    if (entry.id != null) await _remote.deleteWeight(entry.id!);
    s = s.copyWith(
      weights: [for (final w in s.weights) if (w.date != entry.date) w],
      pendingWeights: [for (final w in s.pendingWeights) if (w.date != entry.date) w],
    );
    await _store.save(s);
    return s;
  }

  // ── Measurements ───────────────────────────────────────────────────────────

  Future<BodySnapshot> logMeasurements(List<BodyMeasurement> entries) async {
    if (entries.isEmpty) return load();
    var s = await load();
    var all = s.measurements;
    for (final m in entries) {
      all = _replaceKey(all, m);
    }
    s = s.copyWith(measurements: _ascendingM(all));

    try {
      await _remote.postMeasurements(entries);
      // Take the server's copy so each entry has its id.
      final since = _now().subtract(const Duration(days: _historyDays));
      s = s.copyWith(measurements: _ascendingM(await _remote.listMeasurements(since: since)));
    } on BodyTrackingException catch (e) {
      debugPrint('BodyTracking: measurements kept for later — $e');
      var pending = s.pendingMeasurements;
      for (final m in entries) {
        pending = _replaceKey(pending, m);
      }
      s = s.copyWith(pendingMeasurements: pending);
    }
    await _store.save(s);
    return s;
  }

  Future<BodySnapshot> deleteMeasurement(BodyMeasurement m) async {
    var s = await load();
    if (m.id != null) await _remote.deleteMeasurement(m.id!);
    bool same(BodyMeasurement o) => o.date == m.date && o.site == m.site;
    s = s.copyWith(
      measurements: [for (final o in s.measurements) if (!same(o)) o],
      pendingMeasurements: [for (final o in s.pendingMeasurements) if (!same(o)) o],
    );
    await _store.save(s);
    return s;
  }

  // ── Goal ───────────────────────────────────────────────────────────────────

  /// Sets the goal. Without a start weight it starts from the latest weigh-in.
  Future<BodySnapshot> saveGoal(FitnessGoal goal) async {
    var s = await load();
    final start = goal.startWeightKg ?? (s.weights.isEmpty ? null : s.weights.last.weightKg);
    final wanted = goal.copyWith(startWeightKg: start);
    try {
      s = s.copyWith(goal: await _remote.putGoal(wanted), goalPending: false);
    } on BodyTrackingException catch (e) {
      if (e.error == BodyTrackingError.premiumRequired) rethrow;
      debugPrint('BodyTracking: goal kept for later — $e');
      s = s.copyWith(goal: wanted, goalPending: true);
    }
    await _store.save(s);
    return s;
  }

  Future<BodySnapshot> clearGoal() async {
    var s = await load();
    await _remote.deleteGoal();
    s = s.copyWith(clearGoal: true, goalPending: false);
    await _store.save(s);
    return s;
  }

  // ── Advice and scans ───────────────────────────────────────────────────────

  Future<BodyAdvice> advise(AdviceRequest request) async {
    await load(); // claims the cache for this account before advice goes in it
    final advice = await _remote.advise(request);
    await _store.saveAdvice(advice);
    return advice;
  }

  /// Keeps a body scan's headline numbers on the server. Best effort: the full
  /// result is already saved on the device.
  Future<void> recordScan(Map<String, dynamic> scan) async {
    try {
      await _remote.postScan(scan);
    } on BodyTrackingException catch (e) {
      debugPrint('BodyTracking: scan not stored — $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static List<BodyWeightEntry> _replaceDay(List<BodyWeightEntry> list, BodyWeightEntry e) =>
      [for (final o in list) if (o.date != e.date) o, e];

  static List<BodyMeasurement> _replaceKey(List<BodyMeasurement> list, BodyMeasurement m) =>
      [for (final o in list) if (!(o.date == m.date && o.site == m.site)) o, m];

  static List<BodyWeightEntry> _ascending(List<BodyWeightEntry> l) =>
      [...l]..sort((a, b) => a.date.compareTo(b.date));

  static List<BodyMeasurement> _ascendingM(List<BodyMeasurement> l) =>
      [...l]..sort((a, b) {
          final c = a.date.compareTo(b.date);
          return c != 0 ? c : a.site.index.compareTo(b.site.index);
        });
}
