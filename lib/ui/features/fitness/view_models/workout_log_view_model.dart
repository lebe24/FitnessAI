import 'package:fitness/domain/models/workout_log.dart';
import 'package:fitness/domain/repositories/workout_log_repository.dart';
import 'package:flutter/foundation.dart';

enum WorkoutLogStatus { idle, loading, success, error }

class WorkoutLogViewModel extends ChangeNotifier {
  final WorkoutLogRepository _repo;

  WorkoutLogViewModel(this._repo);

  WorkoutLogStatus _status = WorkoutLogStatus.idle;
  WorkoutLogStatus get status => _status;

  String? _error;
  String? get error => _error;

  WorkoutSessionEntity? _activeSession;
  WorkoutSessionEntity? get activeSession => _activeSession;

  List<WorkoutSessionEntity> _sessions = [];
  List<WorkoutSessionEntity> get sessions => _sessions;

  WorkoutStreak? _streak;
  WorkoutStreak? get streak => _streak;

  // ── Session lifecycle ───────────────────────────────────────────────────────

  /// Call when the user starts a workout (e.g. opens WorkoutPage).
  Future<void> startSession({
    required DateTime date,
    String? dayLabel,
    String? workoutPlanId,
  }) async {
    _setLoading();
    try {
      _activeSession = await _repo.createSession(
        sessionDate: date,
        dayLabel: dayLabel,
        workoutPlanId: workoutPlanId,
      );
      _setSuccess();
    } catch (e) {
      _setError('Failed to start session: $e');
    }
  }

  /// Call when the user taps "Finish Workout".
  Future<void> finishSession(int durationMins) async {
    final id = _activeSession?.id;
    if (id == null) return;
    _setLoading();
    try {
      _activeSession = await _repo.completeSession(
        sessionId: id,
        durationMins: durationMins,
      );
      await _loadStreak();
      _setSuccess();
    } catch (e) {
      _setError('Failed to complete session: $e');
    }
  }

  void clearActiveSession() {
    _activeSession = null;
    notifyListeners();
  }

  // ── Exercise logging ────────────────────────────────────────────────────────

  Future<void> logExercise({
    required String exerciseName,
    required List<SetEntry> sets,
    String? muscleGroup,
    String? equipment,
    String? notes,
  }) async {
    final sessionId = _activeSession?.id;
    if (sessionId == null) return;

    try {
      final log = await _repo.addExerciseLog(
        sessionId: sessionId,
        log: ExerciseLogEntity(
          exerciseName: exerciseName,
          muscleGroup: muscleGroup,
          equipment: equipment,
          orderIndex: _activeSession!.exerciseLogs.length,
          sets: sets,
          notes: notes,
        ),
      );

      // Update local active session with the new log
      final updatedLogs = [..._activeSession!.exerciseLogs, log];
      _activeSession = _activeSession!.copyWith(exerciseLogs: updatedLogs);
      notifyListeners();
    } catch (e) {
      _setError('Failed to log exercise: $e');
    }
  }

  Future<void> updateExerciseLog({
    required String logId,
    required ExerciseLogEntity log,
  }) async {
    try {
      final updated = await _repo.updateExerciseLog(logId: logId, log: log);
      if (_activeSession != null) {
        final updatedLogs = _activeSession!.exerciseLogs
            .map((l) => l.id == logId ? updated : l)
            .toList();
        _activeSession = _activeSession!.copyWith(exerciseLogs: updatedLogs);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update exercise: $e');
    }
  }

  // ── History & progress ──────────────────────────────────────────────────────

  Future<void> loadSessions({DateTime? fromDate, DateTime? toDate}) async {
    _setLoading();
    try {
      _sessions = await _repo.listSessions(
        fromDate: fromDate,
        toDate: toDate,
      );
      _setSuccess();
    } catch (e) {
      _setError('Failed to load sessions: $e');
    }
  }

  Future<void> _loadStreak() async {
    try {
      _streak = await _repo.getStreak();
    } catch (_) {}
  }

  Future<void> loadStreak() async {
    await _loadStreak();
    notifyListeners();
  }

  // ── State helpers ───────────────────────────────────────────────────────────

  void _setLoading() {
    _status = WorkoutLogStatus.loading;
    _error = null;
    notifyListeners();
  }

  void _setSuccess() {
    _status = WorkoutLogStatus.success;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = WorkoutLogStatus.error;
    _error = msg;
    notifyListeners();
  }
}
