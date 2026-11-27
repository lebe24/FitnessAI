import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// How many form analyses this device has run this month.
///
/// Kept on the device, not on the server: nothing about an analysis is stored in
/// the database. That makes the allowance a guide rather than a hard wall (it
/// resets if the app is reinstalled), which is acceptable because the server
/// still limits how fast any one user can call it.
class FormAnalysisUsage {
  /// Analyses per calendar month.
  static const monthlyCap = 30;

  static const _boxName = 'app_settings';
  static const _key = 'form_analysis_runs';

  final DateTime Function() _now;

  FormAnalysisUsage({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Runs recorded in the same calendar month as [at] (UTC).
  Future<int> usedInMonthOf(DateTime at) async {
    final month = _monthKey(at);
    return (await _read()).where((t) => _monthKey(t) == month).length;
  }

  Future<int> usedThisMonth() => usedInMonthOf(_now());

  Future<int> remaining() async =>
      (monthlyCap - await usedThisMonth()).clamp(0, monthlyCap);

  /// Count one successful analysis. A failed one is never recorded, so it does
  /// not cost the user an analysis.
  Future<int> record() async {
    final now = _now();
    final month = _monthKey(now);
    // Older months are no use to anyone; drop them so the list stays small.
    final kept = (await _read()).where((t) => _monthKey(t) == month).toList()..add(now);
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_key, [for (final t in kept) t.toUtc().toIso8601String()]);
      await box.flush();
    } catch (e) {
      // Worst case the user gets one extra analysis, which beats failing a
      // result they already received.
      debugPrint('FormAnalysisUsage: write failed — $e');
    }
    return kept.length;
  }

  Future<List<DateTime>> _read() async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(_key);
      if (raw is! List) return const [];
      return [
        for (final v in raw)
          if (v is String && DateTime.tryParse(v) != null) DateTime.parse(v).toUtc(),
      ];
    } catch (e) {
      debugPrint('FormAnalysisUsage: read failed — $e');
      return const [];
    }
  }

  static String _monthKey(DateTime t) {
    final u = t.toUtc();
    return '${u.year}-${u.month}';
  }
}
