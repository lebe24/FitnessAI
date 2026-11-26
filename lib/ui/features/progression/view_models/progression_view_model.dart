import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/analytics/plan_analytics.dart';
import 'package:fitness/data/services/progression/coach_review_service.dart';
import 'package:fitness/data/services/progression/progression_store.dart';
import 'package:fitness/data/services/workout_log/exercise_history_service.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/progression/progression_engine.dart';
import 'package:fitness/domain/progression/progression_proposal.dart';
import 'package:fitness/domain/use_cases/storage/update_fitness_plan_usecase.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';

/// Keeps the active plan's smart-update state: what the card says, the
/// proposal waiting for review, the log of what was applied, and the settings.
///
/// It does not own the plan. [refresh] is handed the active plan by whoever
/// holds the fitness view model, and the caller reloads that view model after
/// [apply] or [undo] so the calendar picks up the new targets.
class ProgressionViewModel extends ChangeNotifier {
  final ExerciseHistoryService _history;
  final ProgressionStore _store;
  final UpdateFitnessPlanUsecase _updatePlan;
  final DateTime Function() _now;
  final CoachReviewer? _coach;
  final bool Function() _coachAllowed;
  final Future<FitnessGoal?> Function() _activeGoal;
  final Duration _coachTimeout;

  /// The proposal last reported to analytics, so opening the app again with
  /// the same update waiting does not count it twice.
  String? _reportedProposal;

  ProgressionViewModel({
    required ExerciseHistoryService history,
    required ProgressionStore store,
    required UpdateFitnessPlanUsecase updatePlan,
    DateTime Function()? now,
    CoachReviewer? coach,
    bool Function()? coachAllowed,
    Future<FitnessGoal?> Function()? activeGoal,
    Duration coachTimeout = const Duration(seconds: 25),
  })  : _history = history,
        _store = store,
        _updatePlan = updatePlan,
        _now = now ?? DateTime.now,
        _coach = coach,
        _coachAllowed = coachAllowed ?? (() => false),
        _activeGoal = activeGoal ?? (() async => null),
        _coachTimeout = coachTimeout;

  /// Bumped whenever the waiting proposal changes, so a slow coach answer for
  /// an older proposal is dropped instead of overwriting a newer one.
  int _proposalSeq = 0;

  ProgressionSettings _settings = const ProgressionSettings();
  ProgressionStatus _status = ProgressionStatus.building;
  ProgressionProposal? _proposal;
  List<AppliedUpdate> _updates = const [];
  StoredFitnessPlanEntity? _plan;
  int _sessions = 0;
  bool _visible = false;
  bool _busy = false;
  String? _error;
  bool _disposed = false;
  bool _autoApplied = false;

  ProgressionSettings get settings => _settings;
  ProgressionStatus get status => _status;

  /// The update waiting for review, when [status] is ready.
  ProgressionProposal? get proposal => _proposal;

  /// Applied updates, newest first.
  List<AppliedUpdate> get updates => _updates;

  /// False when there is no plan, or the history could not be read, so the
  /// card should not show at all.
  bool get visible => _visible;
  bool get busy => _busy;
  String? get error => _error;

  int get sessionsLogged => _sessions;
  int get sessionsLeft => (ProgressionEngine.minSessions - _sessions).clamp(0, ProgressionEngine.minSessions);
  int get sessionsNeeded => ProgressionEngine.minSessions;
  DateTime? get lastUpdated => _updates.isEmpty ? null : _updates.first.date;
  int get readyCount => _proposal?.actionable.length ?? 0;
  int get currentVersion => _updates.length + 1;

  /// True once, after a refresh applied an update by itself, so the caller can
  /// reload the plan the rest of the app is showing.
  bool takeAutoApplied() {
    final v = _autoApplied;
    _autoApplied = false;
    return v;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Re-reads the history and works out where [plan] stands. If the user chose
  /// automatic updates and one is due, it is applied here.
  Future<void> refresh({required StoredFitnessPlanEntity? plan}) async {
    _plan = plan;
    _settings = await _store.loadSettings();

    if (plan == null) {
      _visible = false;
      _proposal = null;
      _notify();
      return;
    }

    _updates = await _store.updates(plan.id);

    if (!_settings.enabled) {
      _visible = true;
      _status = ProgressionStatus.off;
      _proposal = null;
      _notify();
      return;
    }

    final sessions = await _history.sessions();
    if (sessions == null) {
      // Could not reach the logs. Say nothing rather than guess.
      _visible = false;
      _notify();
      return;
    }

    final now = _now();
    _visible = true;
    _sessions = ProgressionEngine.sessionsInWindow(sessions, now);
    if (_sessions < ProgressionEngine.minSessions) {
      _status = ProgressionStatus.building;
      _proposal = null;
      _notify();
      return;
    }

    final checked = await _store.lastChecked(plan.id);
    final last = _latest(checked, lastUpdated);
    final due = last == null || now.difference(last).inDays >= _settings.intervalDays;
    if (!due) {
      _status = ProgressionStatus.upToDate;
      _proposal = null;
      _notify();
      return;
    }

    _proposal = await _buildProposal(plan, sessions, now);
    if (_proposal == null) {
      // Nothing to change. Look again after the usual interval.
      await _store.markChecked(plan.id, now);
      _status = ProgressionStatus.upToDate;
      _notify();
      return;
    }

    _status = ProgressionStatus.ready;
    final seq = ++_proposalSeq;

    final proposalKey = '${plan.id}:${_proposal!.toVersion}';
    if (_reportedProposal != proposalKey) {
      _reportedProposal = proposalKey;
      PlanAnalytics.updateProposed(changes: _proposal!.actionable.length, deload: _proposal!.isDeload);
    }

    final coaching = _coachable(_proposal!);
    if (coaching) {
      _proposal = _proposal!.withCoach(state: CoachState.reviewing);
    }
    _notify();

    if (coaching) {
      final review = _runCoach(plan, seq);
      // Automatic updates wait for the coach: nothing is applied unreviewed
      // when a review was possible. A manual one shows at once and updates
      // when the answer arrives.
      if (_settings.mode == ApplyMode.automatic) {
        await review;
      } else {
        unawaited(review);
      }
    }

    if (_settings.mode == ApplyMode.automatic && _proposal != null) {
      _autoApplied = await apply(automatic: true);
    }
  }

  /// Whether the coach should look at [p]: Pro, and the update changes loads,
  /// reps or sets. Easy weeks and the return from one are not the coach's.
  bool _coachable(ProgressionProposal p) {
    if (_coach == null || !_coachAllowed() || p.isDeload) return false;
    if (_updates.isNotEmpty && _updates.first.isDeload) return false;
    return p.changes.any((c) => !c.isHold);
  }

  Future<void> _runCoach(StoredFitnessPlanEntity plan, int seq) async {
    final proposal = _proposal;
    if (proposal == null) return;

    CoachResult result;
    try {
      final goal = await _activeGoal();
      result = await _coach!
          .review(proposal, settings: _settings, goalType: goal?.type, focus: goal?.focusMuscles ?? const [])
          .timeout(_coachTimeout);
    } catch (_) {
      result = const CoachResult(decisions: {}, reviewed: false);
    }

    // The proposal may have been applied, dismissed or rebuilt meanwhile.
    if (_disposed || seq != _proposalSeq || _proposal == null) return;

    final merged = ProgressionEngine.applyCoach(proposal, result);
    PlanAnalytics.updateCoachReviewed(
      reviewed: result.reviewed,
      approved: merged.changes.where((c) => c.coachVerdict == CoachVerdict.approve).length,
      softened: merged.changes.where((c) => c.coachVerdict == CoachVerdict.soften).length,
      held: merged.changes.where((c) => c.coachVerdict == CoachVerdict.veto).length,
    );
    if (merged.actionable.isEmpty) {
      // The coach held back every change, so there is nothing to apply.
      await _store.markChecked(plan.id, _now());
      _proposal = null;
      _status = ProgressionStatus.upToDate;
    } else {
      _proposal = merged;
    }
    _notify();
  }

  Future<ProgressionProposal?> _buildProposal(
    StoredFitnessPlanEntity plan,
    List<WorkoutSessionModel> sessions,
    DateTime now,
  ) async {
    final data = plan.workoutPlan.plan;

    // After an easy week the next update is the return to full load.
    final lastUpdate = _updates.isEmpty ? null : _updates.first;
    if (lastUpdate != null && lastUpdate.isDeload && lastUpdate.previous != null) {
      final back = ProgressionEngine.resume(
        plan: data,
        before: lastUpdate.previous!,
        fromVersion: currentVersion,
        sessionsAnalysed: _sessions,
        adherence: 1,
      );
      if (back != null) return back;
    }

    final goal = await _activeGoal();
    return ProgressionEngine.propose(
      plan: data,
      sessions: sessions,
      settings: _settings,
      now: now,
      fromVersion: currentVersion,
      deloadDue: _easyWeekDue(plan, now),
      bodyGoal: goal?.type,
      focusMuscles: goal?.focusMuscles.toSet() ?? const {},
    );
  }

  bool _easyWeekDue(StoredFitnessPlanEntity plan, DateTime now) {
    if (!_settings.deloads) return false;
    DateTime from = plan.createdAt;
    for (final u in _updates) {
      if (u.isDeload) {
        from = u.date;
        break;
      }
    }
    return now.difference(from).inDays >= ProgressionEngine.deloadAfterWeeks * 7;
  }

  /// Applies the waiting update, leaving out the changes at [skipped].
  /// Returns whether it was saved.
  Future<bool> apply({Set<int> skipped = const {}, bool automatic = false}) async {
    final plan = _plan;
    final proposal = _proposal;
    if (plan == null || proposal == null || _busy) return false;

    _busy = true;
    _error = null;
    _notify();
    try {
      final before = plan.workoutPlan.plan;
      final next = ProgressionEngine.apply(before, proposal, skipped: skipped);
      final chosen = [
        for (var i = 0; i < proposal.changes.length; i++)
          if (!proposal.changes[i].isHold && !skipped.contains(i)) i
      ];
      if (chosen.isEmpty) return false;

      final updated = plan.copyWith(
        workoutPlan: WorkoutPlanEntity(plan: next, status: plan.workoutPlan.status),
      );
      await _updatePlan(updated);

      final now = _now();
      final record = AppliedUpdate(
        version: proposal.toVersion,
        date: now,
        changeCount: chosen.length,
        highlights: ProgressionEngine.highlights(proposal, skipped: skipped),
        wasAutomatic: automatic,
        isDeload: proposal.isDeload,
        previous: before.weeklySplit,
      );
      _updates = [record, ..._updates];
      await _store.saveUpdates(plan.id, _updates);
      await _store.markChecked(plan.id, now);

      _plan = updated;
      _proposal = null;
      _proposalSeq++;
      _status = ProgressionStatus.upToDate;
      PlanAnalytics.updateApplied(changes: chosen.length, skipped: skipped.length, automatic: automatic);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  /// "Not this time": keep the plan as it is and look again after the usual
  /// interval.
  Future<void> dismiss() async {
    final plan = _plan;
    if (plan == null) return;
    await _store.markChecked(plan.id, _now());
    _proposal = null;
    _proposalSeq++;
    _status = ProgressionStatus.upToDate;
    PlanAnalytics.updateDismissed();
    _notify();
  }

  /// Puts the plan back the way it was before the latest update.
  Future<bool> undo() async {
    final plan = _plan;
    if (plan == null || _updates.isEmpty || _busy) return false;
    final latest = _updates.first;
    final previous = latest.previous;
    if (previous == null) return false;

    _busy = true;
    _error = null;
    _notify();
    try {
      final restored = ProgressionEngine.withSplit(plan.workoutPlan.plan, previous);
      final updated = plan.copyWith(
        workoutPlan: WorkoutPlanEntity(plan: restored, status: plan.workoutPlan.status),
      );
      await _updatePlan(updated);
      _updates = _updates.sublist(1);
      await _store.saveUpdates(plan.id, _updates);
      await _store.markChecked(plan.id, _now());
      _plan = updated;
      _proposal = null;
      _proposalSeq++;
      _status = ProgressionStatus.upToDate;
      PlanAnalytics.updateUndone();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> saveSettings(ProgressionSettings settings) async {
    _settings = settings;
    await _store.saveSettings(settings);
    await refresh(plan: _plan);
  }

  static DateTime? _latest(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}
