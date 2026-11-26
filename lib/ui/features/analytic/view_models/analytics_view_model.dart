import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/repositories/body_tracking_repository.dart';
import 'package:fitness/data/services/analytics/body_analytics.dart';
import 'package:fitness/data/services/workout_log/exercise_history_service.dart';
import 'package:fitness/domain/body/body_advice.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/goal_progress.dart';
import 'package:fitness/domain/body/muscle_focus.dart';
import 'package:fitness/domain/body/scan_summary.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/domain/models/session_volume.dart';
import 'package:flutter/foundation.dart';

/// Everything the Analytics screen shows about the user's body and goal: the
/// goal and its progress, the weight and measurement logs, the muscle
/// development map, the latest scan and the AI advice.
///
/// It opens on the device copy so the screen is never empty while the network
/// answers, then refreshes from the server. Reads and writes that need the
/// server fail softly: the screen keeps what it has and says it is offline.
class AnalyticsViewModel extends ChangeNotifier {
  final BodyTrackingRepository _repo;
  final ExerciseHistoryService _history;
  final Future<ScanSummary?> Function() _latestScan;
  final bool Function(PremiumFeature) _canUse;
  final DateTime Function() _now;

  AnalyticsViewModel({
    required BodyTrackingRepository repo,
    required ExerciseHistoryService history,
    required Future<ScanSummary?> Function() latestScan,
    required bool Function(PremiumFeature) canUse,
    DateTime Function()? now,
  })  : _repo = repo,
        _history = history,
        _latestScan = latestScan,
        _canUse = canUse,
        _now = now ?? DateTime.now;

  BodySnapshot _snap = BodySnapshot.empty;
  List<WorkoutSessionModel> _sessions = const [];
  List<MuscleStatus> _muscles = const [];
  ScanSummary? _scan;
  BodyAdvice? _advice;
  bool _loading = false;
  bool _offline = false;
  bool _adviceLoading = false;
  BodyTrackingError? _adviceError;
  bool _disposed = false;

  /// Set by the screen, which already has the streak from its own data.
  int streakDays = 0;

  bool get hasBodyTracking => _canUse(PremiumFeature.bodyTracking);
  bool get hasGoalAdvice => _canUse(PremiumFeature.goalAdvice);

  FitnessGoal? get goal => _snap.goal;

  /// Weigh-ins, oldest first.
  List<BodyWeightEntry> get weights => _snap.weights;

  /// Tape measurements, oldest first.
  List<BodyMeasurement> get measurements => _snap.measurements;
  GoalProgress get progress => GoalProgress.of(_snap.goal, _snap.weights, _now());
  List<MuscleStatus> get muscles => _muscles;
  ScanSummary? get scan => _scan;
  BodyAdvice? get advice => _advice;
  bool get loading => _loading;
  bool get offline => _offline;
  bool get hasPending => _snap.hasPending;
  bool get adviceLoading => _adviceLoading;
  BodyTrackingError? get adviceError => _adviceError;
  BodyWeightEntry? get latestWeight => _snap.weights.isEmpty ? null : _snap.weights.last;

  /// The latest reading for each tape-measure site, and the change from the
  /// first reading in the log.
  Map<MeasurementSite, ({double latestCm, double? changeCm})> get measurementSummary {
    final bySite = <MeasurementSite, List<BodyMeasurement>>{};
    for (final m in _snap.measurements) {
      bySite.putIfAbsent(m.site, () => []).add(m);
    }
    return {
      for (final e in bySite.entries)
        e.key: (
          latestCm: e.value.last.valueCm,
          changeCm: e.value.length > 1 ? e.value.last.valueCm - e.value.first.valueCm : null,
        )
    };
  }

  /// Statuses sorted for the lists: strengths best-first, focus areas worst-first.
  List<MuscleStatus> get strengths =>
      [for (final m in _muscles) if (m.level == MuscleLevel.strong) m]
        ..sort((a, b) => b.score.compareTo(a.score));

  List<MuscleStatus> get focusAreas =>
      [for (final m in _muscles) if (m.level == MuscleLevel.focus) m]
        ..sort((a, b) => a.score.compareTo(b.score));

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed)  notifyListeners();
  }

  /// Shows what is on the device, then brings it up to date.
  Future<void> load() async {
    _loading = true;
    // Screens start this from initState, which runs inside a build. Other
    // screens listening to this model must not be told until that build is done.
    await Future<void>.value();
    _notify();

    _snap = await _repo.load();
    _advice ??= await _repo.cachedAdvice();
    await _readTraining();
    _loading = false;
    _notify();

    await refresh();
  }

  /// Reads the server's copy. Keeps the device copy and sets [offline] if it
  /// cannot be reached.
  Future<void> refresh() async {
    await _readTraining();
    try {
      _snap = await _repo.refresh();
      _offline = false;
    } on BodyTrackingException {
      _offline = true;
    }
    _analyse();
    _notify();
  }

  Future<void> _readTraining() async {
    _sessions = await _history.sessions() ?? _sessions;
    _scan = await _latestScan();
    _analyse();
  }

  void _analyse() {
    _muscles = MuscleFocus.analyse(
      sessions: _sessions,
      now: _now(),
      goal: _snap.goal?.type,
      pinned: _snap.goal?.focusMuscles.toSet() ?? const {},
      scanScores: _scan?.groupScores ?? const {},
    );
  }

  // ── Logging ────────────────────────────────────────────────────────────────

  /// Logs a weigh-in for [date] (today by default). Returns false if the
  /// weight is not one a person can have.
  ///
  /// [source] is `sheet` for the full log sheet and `quick` for the pencil on
  /// the Stats card; it only labels the analytics event.
  Future<bool> logWeight(double kg, {DateTime? date, String? note, String source = 'sheet'}) async {
    if (kg < 20 || kg > 400) return false;
    final when = date ?? _now();
    _snap = await _repo.logWeight(BodyWeightEntry(date: when, weightKg: kg, note: note));
    _offline = _snap.hasPending;
    final today = _now();
    BodyAnalytics.weightLogged(
      source: source,
      backdated: DateTime(when.year, when.month, when.day).isBefore(DateTime(today.year, today.month, today.day)),
      hasNote: note != null && note.trim().isNotEmpty,
      offline: _offline,
    );
    _notify();
    return true;
  }

  Future<void> deleteWeight(BodyWeightEntry entry) async {
    try {
      _snap = await _repo.deleteWeight(entry);
    } on BodyTrackingException {
      _offline = true;
    }
    _notify();
  }

  /// Logs the readings in [cm] (centimetres) taken on [date]. Values outside
  /// 5–250 cm are ignored. Returns how many were saved.
  Future<int> logMeasurements(Map<MeasurementSite, double> cm, {DateTime? date}) async {
    final day = date ?? _now();
    final entries = [
      for (final e in cm.entries)
        if (e.value >= 5 && e.value <= 250) BodyMeasurement(date: day, site: e.key, valueCm: e.value)
    ];
    if (entries.isEmpty) return 0;
    _snap = await _repo.logMeasurements(entries);
    _offline = _snap.hasPending;
    BodyAnalytics.measurementsLogged(sites: entries.length);
    _notify();
    return entries.length;
  }

  Future<void> deleteMeasurement(BodyMeasurement entry) async {
    try {
      _snap = await _repo.deleteMeasurement(entry);
    } on BodyTrackingException {
      _offline = true;
    }
    _notify();
  }

  // ── Goal ───────────────────────────────────────────────────────────────────

  Future<bool> saveGoal(FitnessGoal goal) async {
    final replaced = _snap.goal != null;
    final saved = await _saveGoal(goal);
    if (saved) BodyAnalytics.goalSet(goal, replaced: replaced);
    return saved;
  }

  Future<bool> _saveGoal(FitnessGoal goal) async {
    try {
      _snap = await _repo.saveGoal(goal);
      _analyse();
      _adviceError = null;
      _notify();
      return true;
    } on BodyTrackingException {
      return false;
    }
  }

  Future<bool> clearGoal() async {
    final type = _snap.goal?.type;
    try {
      _snap = await _repo.clearGoal();
      _analyse();
      _notify();
      if (type != null) BodyAnalytics.goalCleared(type);
      return true;
    } on BodyTrackingException {
      return false;
    }
  }

  /// Pins or unpins [group] as a focus area. The focus lives on the goal, so
  /// without one this does nothing and returns false: the screen sends the
  /// user to set a goal first.
  Future<bool> setFocus(MuscleGroup group, {required bool focus}) async {
    final g = _snap.goal;
    if (g == null) return false;
    final next = [
      for (final m in g.focusMuscles)
        if (m != group) m,
      if (focus) group,
    ];
    if (next.length > 6) return false;
    // Pinning a muscle is not setting a new goal, so it has its own event.
    final saved = await _saveGoal(g.copyWith(focusMuscles: next));
    if (saved) BodyAnalytics.muscleFocusChanged(group, focus: focus);
    return saved;
  }

  // ── Advice ─────────────────────────────────────────────────────────────────

  /// Asks for fresh advice. [force] skips the server's one-day reuse.
  Future<void> refreshAdvice({bool force = false}) async {
    if (_adviceLoading) return;
    _adviceLoading = true;
    _adviceError = null;
    _notify();
    BodyAnalytics.adviceRequested(forced: force);
    try {
      _advice = await _repo.advise(_adviceRequest(force));
      BodyAnalytics.adviceReceived(_advice!);
    } on BodyTrackingException catch (e) {
      _adviceError = e.error;
      BodyAnalytics.adviceFailed(e.error);
    } finally {
      _adviceLoading = false;
      _notify();
    }
  }

  AdviceRequest _adviceRequest(bool force) {
    final from = _now().subtract(const Duration(days: MuscleFocus.windowDays));
    final recent = [
      for (final s in _sessions)
        if (!s.sessionDate.isBefore(from) && SessionVolume.exercisesOf(s).isNotEmpty) s
    ];
    final volume = recent.fold<double>(0, (t, s) => t + SessionVolume.fromSession(s).totalVolumeKg);
    return AdviceRequest(
      sessionsLogged: _sessions.length,
      workoutsPerWeek: double.parse((recent.length / (MuscleFocus.windowDays / 7)).toStringAsFixed(1)),
      volumeLast28DaysKg: volume.roundToDouble(),
      streakDays: streakDays,
      muscles: [for (final m in _muscles) if (m.level != MuscleLevel.untrained) m],
      forceRefresh: force,
    );
  }
}
