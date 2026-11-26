import 'package:fitness/domain/coach/session_load.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Today's "how do you feel?" answer, shared by every exercise page that day.
/// It stays on the phone.
abstract class CheckInStore {
  Future<Soreness?> read(DateTime day);
  Future<void> save(DateTime day, Soreness? answer);
}

class HiveCheckInStore implements CheckInStore {
  static const _box = 'coach_checkin';
  static const _key = 'today';

  static String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  Future<Soreness?> read(DateTime day) async {
    try {
      final box = await Hive.openBox(_box);
      final v = box.get(_key);
      if (v is! Map || v['day'] != _day(day)) return null;
      return Soreness.values.asNameMap()[v['answer']];
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(DateTime day, Soreness? answer) async {
    try {
      final box = await Hive.openBox(_box);
      if (answer == null) {
        await box.delete(_key);
      } else {
        // Only today's answer is kept: yesterday's soreness says nothing now.
        await box.put(_key, {'day': _day(day), 'answer': answer.name});
      }
    } catch (_) {}
  }
}

/// Kept in memory, for tests and previews.
class MemoryCheckInStore implements CheckInStore {
  final _answers = <String, Soreness>{};

  @override
  Future<Soreness?> read(DateTime day) async => _answers[HiveCheckInStore._day(day)];

  @override
  Future<void> save(DateTime day, Soreness? answer) async {
    final k = HiveCheckInStore._day(day);
    if (answer == null) {
      _answers.remove(k);
    } else {
      _answers[k] = answer;
    }
  }
}
