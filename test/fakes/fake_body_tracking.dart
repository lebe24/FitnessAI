import 'package:fitness/data/services/body/body_tracking_remote.dart';
import 'package:fitness/data/services/body/body_tracking_store.dart';
import 'package:fitness/domain/body/body_advice.dart';
import 'package:fitness/domain/body/body_models.dart';

/// A server in memory. Set [offline] to make every call fail as if the phone
/// had no signal, and [adviceError] to make advice fail the way the backend would.
class FakeBodyRemote implements BodyTrackingRemote {
  bool offline = false;
  BodyTrackingError? adviceError;
  FitnessGoal? goal;
  final weights = <BodyWeightEntry>[];
  final measurements = <BodyMeasurement>[];
  final scans = <Map<String, dynamic>>[];
  BodyAdvice? nextAdvice;
  int adviceCalls = 0;
  int syncCalls = 0;
  AdviceRequest? lastAdviceRequest;
  int _ids = 0;

  void _check() {
    if (offline) throw const BodyTrackingException(BodyTrackingError.offline);
  }

  @override
  Future<FitnessGoal?> getGoal() async {
    _check();
    return goal;
  }

  @override
  Future<FitnessGoal> putGoal(FitnessGoal g) async {
    _check();
    return goal = FitnessGoal(
      id: 'goal-${++_ids}',
      type: g.type,
      startWeightKg: g.startWeightKg,
      targetWeightKg: g.targetWeightKg,
      targetDate: g.targetDate,
      weeklyRateKg: g.weeklyRateKg,
      focusMuscles: g.focusMuscles,
    );
  }

  @override
  Future<void> deleteGoal() async {
    _check();
    goal = null;
  }

  @override
  Future<List<BodyWeightEntry>> listWeights({DateTime? since}) async {
    _check();
    return [...weights];
  }

  @override
  Future<BodyWeightEntry> postWeight(BodyWeightEntry e) async {
    _check();
    weights.removeWhere((w) => w.date == e.date);
    final saved = BodyWeightEntry(id: 'w-${++_ids}', date: e.date, weightKg: e.weightKg, note: e.note);
    weights.add(saved);
    return saved;
  }

  @override
  Future<void> deleteWeight(String id) async {
    _check();
    weights.removeWhere((w) => w.id == id);
  }

  @override
  Future<List<BodyMeasurement>> listMeasurements({DateTime? since}) async {
    _check();
    return [...measurements];
  }

  @override
  Future<void> postMeasurements(List<BodyMeasurement> entries) async {
    _check();
    for (final m in entries) {
      measurements.removeWhere((o) => o.date == m.date && o.site == m.site);
      measurements.add(BodyMeasurement(id: 'm-${++_ids}', date: m.date, site: m.site, valueCm: m.valueCm));
    }
  }

  @override
  Future<void> deleteMeasurement(String id) async {
    _check();
    measurements.removeWhere((m) => m.id == id);
  }

  @override
  Future<void> sync({
    required List<BodyWeightEntry> weights,
    required List<BodyMeasurement> measurements,
  }) async {
    _check();
    syncCalls++;
    for (final w in weights) {
      await postWeight(w);
    }
    await postMeasurements(measurements);
  }

  @override
  Future<void> postScan(Map<String, dynamic> scan) async {
    _check();
    scans.add(scan);
  }

  @override
  Future<BodyAdvice> advise(AdviceRequest request) async {
    _check();
    adviceCalls++;
    lastAdviceRequest = request;
    if (adviceError != null) throw BodyTrackingException(adviceError!);
    return nextAdvice!;
  }
}

class MemoryBodyStore implements BodyTrackingStore {
  BodySnapshot snapshot = BodySnapshot.empty;
  BodyAdvice? advice;

  @override
  Future<BodySnapshot> load() async => snapshot;
  @override
  Future<void> save(BodySnapshot s) async => snapshot = s;
  @override
  Future<BodyAdvice?> loadAdvice() async => advice;
  @override
  Future<void> saveAdvice(BodyAdvice a) async => advice = a;
  @override
  Future<void> clearAdvice() async => advice = null;
}
