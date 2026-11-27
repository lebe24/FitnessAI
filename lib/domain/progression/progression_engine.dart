import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/muscle_coverage.dart';
import 'package:fitness/domain/models/session_volume.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/progression/progression_proposal.dart';

/// What the user is training for, read from the plan's free-text goal.
enum GoalKind { hypertrophy, strength, fatLoss, general }

GoalKind goalKindOf(String goal) {
  final g = goal.toLowerCase();
  if (RegExp(r'strength|power|powerlift|stronger').hasMatch(g)) return GoalKind.strength;
  if (RegExp(r'fat|lose|loss|cut|lean|shred|slim').hasMatch(g)) return GoalKind.fatLoss;
  if (RegExp(r'muscle|hypertrophy|bulk|mass|build|size|gain').hasMatch(g)) return GoalKind.hypertrophy;
  return GoalKind.general;
}

/// The progression rules a body goal calls for.
GoalKind goalKindForBodyGoal(GoalType type) => switch (type) {
      GoalType.loseWeight => GoalKind.fatLoss,
      GoalType.gainWeight || GoalType.buildMuscle => GoalKind.hypertrophy,
      GoalType.maintain => GoalKind.general,
    };

/// The coach's review of one change, as the app gets it.
class CoachDecision {
  final CoachVerdict verdict;
  final String? reason;
  const CoachDecision(this.verdict, [this.reason]);
}

/// The coach's whole review. Decisions are keyed by change id, `c0`, `c1`, in
/// the order of the proposal.
class CoachResult {
  final Map<String, CoachDecision> decisions;
  final String? note;

  /// False when the coach could not review and every change was simply approved.
  final bool reviewed;
  const CoachResult({required this.decisions, this.note, required this.reviewed});
}

/// Turns what the user logged into a proposed update to their plan.
///
/// Pure: the same plan, sessions and settings always give the same proposal,
/// and nothing here reads a clock, a database or the network. That is what
/// makes it safe to run on every launch and easy to test.
///
/// The rules are the standard double-progression approach:
///
///  * Finish every set at the top of the rep range, for enough sessions in a
///    row, and the weight goes up.
///  * A single fixed rep target goes up by a rep first, then weight.
///  * Miss a set last time and the exercise is held until it is repeated.
///  * Three sessions without progress, with a miss, drops the load by about
///    10% to break the stall.
///  * Hypertrophy only: a comfortable isolation exercise gains a fourth set.
///  * A planned easy week every six weeks, then a return to full load.
class ProgressionEngine {
  ProgressionEngine._();

  /// Sessions with logged sets needed before the first update.
  static const minSessions = 4;

  /// How far back the history is read.
  static const windowWeeks = 6;

  /// Weeks of hard training before an easy week is proposed.
  static const deloadAfterWeeks = 6;

  /// Fraction of the load kept in a stall drop and in an easy week.
  static const _deloadFactor = 0.9;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Logged sessions in the history window, the number the card counts toward
  /// [minSessions].
  static int sessionsInWindow(List<WorkoutSessionModel> sessions, DateTime now) {
    final from = _windowStart(now);
    var n = 0;
    for (final s in sessions) {
      if (s.sessionDate.isBefore(from)) continue;
      if (SessionVolume.exercisesOf(s).isNotEmpty) n++;
    }
    return n;
  }

  /// The proposal for [plan], or null when there is nothing to change.
  ///
  /// [deloadDue] asks for the planned easy week instead of normal progress.
  static ProgressionProposal? propose({
    required WorkoutPlanData plan,
    required List<WorkoutSessionModel> sessions,
    required ProgressionSettings settings,
    required DateTime now,
    required int fromVersion,
    bool deloadDue = false,
    GoalType? bodyGoal,
    Set<MuscleGroup> focusMuscles = const {},
  }) {
    final from = _windowStart(now);
    final analysed = sessionsInWindow(sessions, now);
    if (analysed < minSessions) return null;

    // The goal the user set on the Analytics screen wins over the free text the
    // plan was generated with.
    final goal = bodyGoal != null ? goalKindForBodyGoal(bodyGoal) : goalKindOf(plan.goal);
    final planned = plan.weeklySplit.days.length * windowWeeks;
    final adherence = planned == 0 ? 0.0 : (analysed / planned).clamp(0.0, 1.0);

    final changes = <PlannedChange>[];
    var personalBests = 0;

    final days = plan.weeklySplit.days;
    for (var d = 0; d < days.length; d++) {
      final day = days[d];
      for (var e = 0; e < day.exercises.length; e++) {
        final ex = day.exercises[e];
        // History is read over the window for decisions, but personal bests
        // compare the window against everything before it.
        final all = ExerciseHistory.fromSessions(sessions, ex.name, limit: 40);
        final inWindow = ExerciseHistory([
          for (final h in all.entries)
            if (!h.date.isBefore(DateTime(from.year, from.month, from.day))) h
        ]);
        if (inWindow.isEmpty) continue;
        if (_isNewBest(all, from)) personalBests++;

        final _Decision? decision = deloadDue
            ? _scheduledDeload(ex, inWindow)
            : _evaluate(ex, inWindow, goal, settings, adherence, _trainsFocus(ex.name, focusMuscles));
        if (decision == null) continue;

        changes.add(PlannedChange(
          day: _shortDay(day.day),
          dayFocus: day.focus,
          exercise: ex.name,
          kind: decision.kind,
          before: _label(ex, decision.baseKg),
          after: _label(decision.updated, decision.updated.targetKg),
          badge: decision.badge,
          reason: decision.reason,
          dayIndex: d,
          exerciseIndex: e,
          updated: decision.updated,
          previousKg: decision.baseKg,
        ));
      }
    }

    if (changes.where((c) => !c.isHold).isEmpty) return null;

    return ProgressionProposal(
      planName: plan.trainingSplit,
      goal: plan.goal,
      fromVersion: fromVersion,
      toVersion: fromVersion + 1,
      weeks: windowWeeks,
      sessionsAnalysed: analysed,
      adherence: adherence,
      newPersonalBests: personalBests,
      isDeload: deloadDue,
      changes: changes,
    );
  }

  /// The proposal that undoes an easy week: every exercise the easy week
  /// changed goes back to [before].
  static ProgressionProposal? resume({
    required WorkoutPlanData plan,
    required WeeklySplit before,
    required int fromVersion,
    required int sessionsAnalysed,
    required double adherence,
  }) {
    final changes = <PlannedChange>[];
    final days = plan.weeklySplit.days;
    for (var d = 0; d < days.length && d < before.days.length; d++) {
      for (var e = 0; e < days[d].exercises.length && e < before.days[d].exercises.length; e++) {
        final now = days[d].exercises[e];
        final was = before.days[d].exercises[e];
        if (now.name != was.name) continue;
        if (now.sets == was.sets && now.targetKg == was.targetKg) continue;

        final kgDelta = (was.targetKg ?? 0) - (now.targetKg ?? 0);
        final setDelta = was.sets - now.sets;
        changes.add(PlannedChange(
          day: _shortDay(days[d].day),
          dayFocus: days[d].focus,
          exercise: now.name,
          kind: kgDelta > 0 ? ChangeKind.load : ChangeKind.sets,
          before: _label(now, now.targetKg),
          after: _label(was, was.targetKg),
          badge: kgDelta > 0 ? '+${formatKg(kgDelta)} kg' : '+$setDelta set${setDelta == 1 ? '' : 's'}',
          reason: 'Easy week is done. Back to your full load.',
          dayIndex: d,
          exerciseIndex: e,
          updated: now.copyWith(sets: was.sets, targetKg: was.targetKg),
        ));
      }
    }
    if (changes.isEmpty) return null;
    return ProgressionProposal(
      planName: plan.trainingSplit,
      goal: plan.goal,
      fromVersion: fromVersion,
      toVersion: fromVersion + 1,
      weeks: windowWeeks,
      sessionsAnalysed: sessionsAnalysed,
      adherence: adherence,
      newPersonalBests: 0,
      isDeload: false,
      changes: changes,
    );
  }

  /// [plan] with every change in [proposal] applied, except the indexes in
  /// [skipped]. Holds change nothing. A change whose exercise is no longer at
  /// its place in the plan is left out rather than applied to the wrong one.
  static WorkoutPlanData apply(
    WorkoutPlanData plan,
    ProgressionProposal proposal, {
    Set<int> skipped = const {},
  }) {
    final days = [for (final d in plan.weeklySplit.days) [...d.exercises]];

    for (var i = 0; i < proposal.changes.length; i++) {
      final c = proposal.changes[i];
      if (skipped.contains(i) || c.isHold || c.updated == null) continue;
      if (c.dayIndex < 0 || c.dayIndex >= days.length) continue;
      final row = days[c.dayIndex];
      if (c.exerciseIndex < 0 || c.exerciseIndex >= row.length) continue;
      if (row[c.exerciseIndex].name != c.exercise) continue;
      row[c.exerciseIndex] = c.updated!;
    }

    return WorkoutPlanData(
      analysisSummary: plan.analysisSummary,
      physiqueRating: plan.physiqueRating,
      goal: plan.goal,
      focus: plan.focus,
      trainingSplit: plan.trainingSplit,
      equipment: plan.equipment,
      weeklySplit: WeeklySplit(days: [
        for (var d = 0; d < plan.weeklySplit.days.length; d++)
          WorkoutDay(
            day: plan.weeklySplit.days[d].day,
            focus: plan.weeklySplit.days[d].focus,
            exercises: days[d],
            tip: plan.weeklySplit.days[d].tip,
          ),
      ]),
      trainingGuidelines: plan.trainingGuidelines,
      nutritionGuidelines: plan.nutritionGuidelines,
      extraTips: plan.extraTips,
    );
  }

  /// A plan with its split replaced, used to restore a snapshot.
  static WorkoutPlanData withSplit(WorkoutPlanData plan, WeeklySplit split) => WorkoutPlanData(
        analysisSummary: plan.analysisSummary,
        physiqueRating: plan.physiqueRating,
        goal: plan.goal,
        focus: plan.focus,
        trainingSplit: plan.trainingSplit,
        equipment: plan.equipment,
        weeklySplit: split,
        trainingGuidelines: plan.trainingGuidelines,
        nutritionGuidelines: plan.nutritionGuidelines,
        extraTips: plan.extraTips,
      );

  /// [proposal] with the coach's decisions applied.
  ///
  /// The coach can only slow things down. Approving changes nothing but adds
  /// their sentence. Softening halves a weight step, and holds any other kind
  /// of change, since a one-rep or one-set step has nothing smaller. A veto
  /// holds the exercise. A recovery week is never changed.
  static ProgressionProposal applyCoach(ProgressionProposal proposal, CoachResult result) {
    if (!result.reviewed) {
      return proposal.withCoach(state: CoachState.unavailable);
    }
    final out = <PlannedChange>[];
    for (var i = 0; i < proposal.changes.length; i++) {
      final c = proposal.changes[i];
      final d = result.decisions['c$i'];
      if (d == null || c.isHold) {
        out.add(c);
        continue;
      }
      if (c.kind == ChangeKind.deload || d.verdict == CoachVerdict.approve) {
        out.add(c.reviewed(verdict: CoachVerdict.approve, coachReason: d.reason));
        continue;
      }
      out.add(d.verdict == CoachVerdict.soften ? _soften(c, d.reason) : _hold(c, d.reason));
    }
    return proposal.withCoach(changes: out, state: CoachState.reviewed, note: result.note);
  }

  static PlannedChange _hold(PlannedChange c, String? reason) => c.reviewed(
        verdict: CoachVerdict.veto,
        coachReason: reason,
        kind: ChangeKind.hold,
        after: c.before,
        badge: 'Held',
        reason: reason ?? 'Your coach is holding this one for now.',
        clearUpdated: true,
      );

  static PlannedChange _soften(PlannedChange c, String? reason) {
    final target = c.updated?.targetKg;
    final from = c.previousKg;
    if (c.kind != ChangeKind.load || target == null || from == null) return _hold(c, reason);

    final half = roundKg(from + (target - from) / 2);
    // Rounding to half a kilo can land back on the full step, which is no softer.
    if (half <= from || half >= target) return _hold(c, reason);

    final eased = c.updated!.copyWith(targetKg: half);
    return c.reviewed(
      verdict: CoachVerdict.soften,
      coachReason: reason,
      after: '${eased.sets} × ${eased.reps} · ${formatKg(half)} kg',
      badge: '+${formatKg(half - from)} kg',
      updated: eased,
    );
  }

  /// Two or three short phrases for the history list: `Bench +2.5 kg`.
  static List<String> highlights(ProgressionProposal proposal, {Set<int> skipped = const {}}) {
    final out = <String>[];
    for (var i = 0; i < proposal.changes.length && out.length < 3; i++) {
      final c = proposal.changes[i];
      if (c.isHold || skipped.contains(i)) continue;
      out.add('${_shortName(c.exercise)} ${c.badge}');
    }
    return out;
  }

  // ── One exercise ──────────────────────────────────────────────────────────

  /// What the rules would do with one exercise next time: the same decision the
  /// weekly update makes. Null when there is nothing to change yet, or when the
  /// target is not a number of reps (see [repRange]).
  ///
  /// [history] should already be cut to the [windowWeeks] window.
  static ExerciseDecision? decideFor({
    required Exercise exercise,
    required ExerciseHistory history,
    required GoalKind goal,
    ProgressionSettings settings = const ProgressionSettings(),
    double adherence = 1,
    bool trainsFocus = false,
  }) {
    if (history.isEmpty) return null;
    final d = _evaluate(exercise, history, goal, settings, adherence, trainsFocus);
    return d == null
        ? null
        : ExerciseDecision(kind: d.kind, badge: d.badge, reason: d.reason, updated: d.updated, baseKg: d.baseKg);
  }

  /// The low and high end of a rep target such as `8-10`, or null for timed and
  /// to-failure targets.
  static ({int lo, int hi})? repRange(String reps) {
    final r = _RepRange.parse(reps);
    return r == null ? null : (lo: r.lo, hi: r.hi);
  }

  /// Whether [exercise] works one of the muscles in [focus].
  static bool trainsAny(String exercise, Set<MuscleGroup> focus) => _trainsFocus(exercise, focus);

  // ── Rules ─────────────────────────────────────────────────────────────────

  static _Decision? _evaluate(
    Exercise ex,
    ExerciseHistory history,
    GoalKind goal,
    ProgressionSettings settings,
    double adherence,
    bool trainsFocus,
  ) {
    final range = _RepRange.parse(ex.reps);
    if (range == null) return null; // timed or to-failure: nothing to compare

    final entries = history.entries;
    final last = entries.first;
    final loaded = last.hasLoad;
    final lastTop = last.bestSet?.weightKg;

    // The weight the plan asks for. Plans from before targets existed have
    // none, so the last working weight stands in.
    final ref = loaded ? (ex.targetKg ?? lastTop) : null;

    bool qualifies(ExerciseHistoryEntry h) {
      if (!loaded) return true;
      final top = h.bestSet?.weightKg;
      return top != null && ref != null && top >= ref - 0.01;
    }

    List<LoggedSet> working(ExerciseHistoryEntry h) {
      final top = h.bestSet?.weightKg;
      if (top == null) return h.sets;
      // Warm-up sets are lighter; they are not what the rep target is about.
      return [for (final s in h.sets) if ((s.weightKg ?? 0) >= top * 0.85) s];
    }

    bool fullSets(ExerciseHistoryEntry h) => working(h).length >= ex.sets;
    bool atLeastLow(ExerciseHistoryEntry h) =>
        working(h).every((s) => (s.reps ?? s.durationSec ?? 0) >= range.lo);
    bool atTop(ExerciseHistoryEntry h) =>
        working(h).every((s) => (s.reps ?? s.durationSec ?? 0) >= range.hi);
    bool hit(ExerciseHistoryEntry h) => qualifies(h) && fullSets(h) && atTop(h);

    // 1. A stall: three sessions in a row short of the top, no progress across
    // them, and the last one missed outright.
    if (loaded && entries.length >= 3 && ref != null) {
      final missed = !fullSets(last) || !atLeastLow(last);
      final struggling = !hit(entries[0]) && !hit(entries[1]) && !hit(entries[2]);
      if (missed && struggling && !_improved(entries[0], entries[2])) {
        final base = lastTop! > ref ? lastTop : ref;
        final drop = roundKg(base * _deloadFactor);
        return _Decision(
          kind: ChangeKind.deload,
          badge: '−10%',
          baseKg: ref,
          reason: 'No progress for 3 sessions. A lighter block usually breaks a stall.',
          updated: ex.copyWith(targetKg: drop),
        );
      }
    }

    // 2. Enough sessions at the top of the range: progress.
    var streak = 0;
    for (final h in entries) {
      if (!hit(h)) break;
      streak++;
    }
    final required = switch (settings.pace) {
      ProgressionPace.steady => 3,
      ProgressionPace.balanced => 2,
      ProgressionPace.ambitious => 1,
    };
    final sessionsText = streak == 1 ? 'your last session' : 'your last $streak sessions';

    if (streak >= required) {
      final base = loaded ? _max(ref ?? 0, lastTop ?? 0) : null;

      // A single fixed target moves by reps first, until the goal's ceiling.
      if (range.single && range.hi < _repCeiling(goal)) {
        final n = range.hi + 1;
        return _Decision(
          kind: ChangeKind.reps,
          badge: '+1 rep',
          baseKg: ref,
          reason: loaded
              ? 'You reached ${range.hi} reps on every set. Reps first, then weight.'
              : 'You reached ${range.hi} reps on every set in $sessionsText.',
          updated: ex.copyWith(reps: '$n', targetKg: base),
        );
      }

      if (loaded) {
        final step = _step(ex.name, base!);
        return _Decision(
          kind: ChangeKind.load,
          badge: '+${formatKg(step)} kg',
          baseKg: ref,
          reason: 'You hit ${range.hi} reps on every set in $sessionsText.',
          updated: ex.copyWith(targetKg: roundKg(base + step)),
        );
      }

      // Bodyweight: the target itself moves up.
      final bump = range.single ? 1 : 2;
      if (range.hi + bump > 30) return null;
      final reps = range.single ? '${range.hi + 1}' : '${range.lo + bump}-${range.hi + bump}';
      return _Decision(
        kind: ChangeKind.reps,
        badge: '+$bump rep${bump == 1 ? '' : 's'}',
        baseKg: null,
        reason: 'You reached ${range.hi} reps on every set in $sessionsText.',
        updated: ex.copyWith(reps: reps),
      );
    }

    // 3. The last session missed: hold until it is repeated.
    if (!fullSets(last) || !atLeastLow(last)) {
      if (loaded && ref != null && !qualifies(last)) {
        return _Decision(
          kind: ChangeKind.hold,
          badge: 'Hold',
          baseKg: ref,
          reason: 'Last session was at ${formatKg(lastTop!)} kg, under the ${formatKg(ref)} kg target. Hit the target first.',
          updated: ex,
        );
      }
      final sets = working(last);
      final String why;
      if (sets.length < ex.sets) {
        why = 'You finished ${sets.length} of ${ex.sets} sets last session. Repeat it before adding weight.';
      } else {
        final i = sets.indexWhere((s) => (s.reps ?? s.durationSec ?? 0) < range.lo);
        final r = sets[i].reps ?? sets[i].durationSec ?? 0;
        why = 'Set ${i + 1} fell to $r reps last session. Repeat it before adding weight.';
      }
      return _Decision(kind: ChangeKind.hold, badge: 'Hold', baseKg: ref, reason: why, updated: ex);
    }

    // 4. Comfortable and not yet at the top: a hypertrophy isolation lift can
    // take a fourth set.
    if (goal == GoalKind.hypertrophy &&
        ex.sets == 3 &&
        adherence >= 0.8 &&
        entries.length >= 3 &&
        (!_isCompound(ex.name) || trainsFocus) &&
        entries.take(3).every((h) => qualifies(h) && fullSets(h) && atLeastLow(h))) {
      return _Decision(
        kind: ChangeKind.sets,
        badge: '+1 set',
        baseKg: ref,
        reason: 'You have finished every set for 3 sessions. An extra set adds volume.',
        updated: ex.copyWith(sets: 4, targetKg: ref),
      );
    }

    return null;
  }

  static _Decision? _scheduledDeload(Exercise ex, ExerciseHistory history) {
    final last = history.entries.first;
    final top = last.bestSet?.weightKg;
    final loaded = last.hasLoad && top != null;

    if (loaded) {
      final base = _max(ex.targetKg ?? 0, top);
      final sets = ex.sets > 2 ? ex.sets - 1 : ex.sets;
      return _Decision(
        kind: ChangeKind.deload,
        badge: '−10%',
        baseKg: ex.targetKg ?? top,
        reason: 'Planned easy week. Fewer sets and a lighter load let you recover.',
        updated: ex.copyWith(sets: sets, targetKg: roundKg(base * _deloadFactor)),
      );
    }
    if (ex.sets > 2) {
      return _Decision(
        kind: ChangeKind.deload,
        badge: '−1 set',
        baseKg: null,
        reason: 'Planned easy week. One set fewer lets you recover.',
        updated: ex.copyWith(sets: ex.sets - 1),
      );
    }
    return null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static DateTime _windowStart(DateTime now) {
    final d = DateTime(now.year, now.month, now.day);
    return d.subtract(const Duration(days: windowWeeks * 7));
  }

  /// A new best is a heavier top set in the window than anything before it.
  static bool _isNewBest(ExerciseHistory all, DateTime from) {
    final start = DateTime(from.year, from.month, from.day);
    double? before;
    double? within;
    for (final h in all.entries) {
      final w = h.bestSet?.weightKg;
      if (w == null) continue;
      if (h.date.isBefore(start)) {
        if (before == null || w > before) before = w;
      } else {
        if (within == null || w > within) within = w;
      }
    }
    return before != null && within != null && within > before;
  }

  /// Whether [a] is better than [b]: more weight, or the same weight for more
  /// reps. Bodyweight work compares reps.
  static bool _improved(ExerciseHistoryEntry a, ExerciseHistoryEntry b) {
    final sa = a.bestSet, sb = b.bestSet;
    if (sa == null || sb == null) return false;
    final wa = sa.weightKg ?? 0, wb = sb.weightKg ?? 0;
    if (wa != wb) return wa > wb;
    return (sa.reps ?? sa.durationSec ?? 0) > (sb.reps ?? sb.durationSec ?? 0);
  }

  static int _repCeiling(GoalKind goal) => switch (goal) {
        GoalKind.strength => 6,
        GoalKind.hypertrophy => 12,
        GoalKind.fatLoss => 15,
        GoalKind.general => 12,
      };

  static final _compoundWords = RegExp(
      r'squat|deadlift|bench|press|row|pull.?up|chin.?up|dip|lunge|hip thrust|clean|snatch|pulldown');
  /// Whether an exercise works one of the muscles the user chose to prioritise.
  static bool _trainsFocus(String exercise, Set<MuscleGroup> focus) {
    if (focus.isEmpty) return false;
    for (final slug in MuscleCoverage.musclesFor(name: exercise)) {
      final g = MuscleGroup.forSlug(slug);
      if (g != null && focus.contains(g)) return true;
    }
    return false;
  }

  static bool _isCompound(String name) => _compoundWords.hasMatch(name.toLowerCase());

  static final _lowerWords = RegExp(r'squat|deadlift|leg press|hip thrust|lunge');

  /// How much to add, in kg. Big lower-body lifts jump more; small dumbbells
  /// move by smaller steps.
  static double _step(String name, double base) {
    final n = name.toLowerCase();
    if (_lowerWords.hasMatch(n)) return 5;
    if (base < 20) return 1;
    if (n.contains('dumbbell') && base < 40) return 2;
    return 2.5;
  }

  static double roundKg(double kg) => (kg * 2).round() / 2;
  static double _max(double a, double b) => a > b ? a : b;

  static String _label(Exercise ex, double? kg) =>
      '${ex.sets} × ${ex.reps}${kg == null ? '' : ' · ${formatKg(kg)} kg'}';

  static String _shortDay(String day) {
    final d = day.trim();
    return d.length <= 3 ? d : d.substring(0, 3);
  }

  static String _shortName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'\b(barbell|dumbbell|conventional|machine|cable|seated|standing)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? name : cleaned;
  }
}

/// The rules' answer for one exercise.
class ExerciseDecision {
  final ChangeKind kind;

  /// `+2.5 kg`, `+1 rep`, `Hold`.
  final String badge;
  final String reason;
  final Exercise updated;

  /// The weight it was decided from, when there is one.
  final double? baseKg;

  const ExerciseDecision({
    required this.kind,
    required this.badge,
    required this.reason,
    required this.updated,
    required this.baseKg,
  });
}

class _Decision {
  final ChangeKind kind;
  final String badge;
  final String reason;
  final Exercise updated;

  /// The weight shown on the "before" side, when the plan or history has one.
  final double? baseKg;

  const _Decision({
    required this.kind,
    required this.badge,
    required this.reason,
    required this.updated,
    required this.baseKg,
  });
}

/// A rep target such as `8-10`, `10`, or `12 per leg`.
class _RepRange {
  final int lo;
  final int hi;
  const _RepRange(this.lo, this.hi);

  bool get single => lo == hi;

  /// Null for targets that are not a number of reps — timed holds, AMRAP,
  /// "to failure" — which a rep rule cannot judge.
  static _RepRange? parse(String reps) {
    final r = reps.toLowerCase();
    if (RegExp(r'sec|min|amrap|fail|max').hasMatch(r)) return null;
    final range = RegExp(r'(\d+)\s*[–-]\s*(\d+)').firstMatch(r);
    if (range != null) {
      final a = int.parse(range.group(1)!), b = int.parse(range.group(2)!);
      return a <= b ? _RepRange(a, b) : _RepRange(b, a);
    }
    final one = RegExp(r'(\d+)').firstMatch(r);
    if (one == null) return null;
    final n = int.parse(one.group(1)!);
    return _RepRange(n, n);
  }
}
