import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/progression/progression_engine.dart';
import 'package:fitness/domain/progression/progression_proposal.dart';

/// What the coach advises for the exercise on screen.
enum CoachAction { addWeight, addReps, addSet, hold, easeOff, findWeight, timed }

/// A rep range a goal is usually trained in.
class RepRange {
  final int lo;
  final int hi;
  const RepRange(this.lo, this.hi);

  String get label => '$lo–$hi';

  static RepRange forGoal(GoalKind goal) => switch (goal) {
        GoalKind.strength => const RepRange(3, 6),
        GoalKind.hypertrophy => const RepRange(6, 12),
        GoalKind.fatLoss => const RepRange(12, 15),
        GoalKind.general => const RepRange(8, 12),
      };
}

String goalName(GoalKind goal) => switch (goal) {
      GoalKind.strength => 'strength',
      GoalKind.hypertrophy => 'muscle growth',
      GoalKind.fatLoss => 'fat loss',
      GoalKind.general => 'general fitness',
    };

/// Sets, reps and weight for next time. [weightKg] is null for bodyweight work,
/// or when there is nothing to base a weight on.
class SetPrescription {
  final double? weightKg;
  final int sets;
  final String reps;
  const SetPrescription({this.weightKg, required this.sets, required this.reps});

  /// `4 × 10 @ 30 kg`
  String get label => '$sets × $reps${weightKg == null ? '' : ' @ ${formatKg(weightKg!)} kg'}';

  @override
  bool operator ==(Object other) =>
      other is SetPrescription && other.weightKg == weightKg && other.sets == sets && other.reps == reps;

  @override
  int get hashCode => Object.hash(weightKg, sets, reps);
}

class ExerciseRecommendation {
  final CoachAction action;
  final SetPrescription target;

  /// `+2.5 kg`, `Hold`.
  final String badge;
  final String reason;
  final GoalKind goal;
  final RepRange goalRange;

  /// A second way to do it, in the goal's rep range, when the plan's reps sit
  /// outside it.
  final SetPrescription? alternative;
  final String? alternativeReason;

  const ExerciseRecommendation({
    required this.action,
    required this.target,
    required this.badge,
    required this.reason,
    required this.goal,
    required this.goalRange,
    this.alternative,
    this.alternativeReason,
  });

  /// The numbers come from rules, never from a model.
  static ExerciseRecommendation of({
    required Exercise exercise,
    required ExerciseHistory history,
    required GoalKind goal,
    required DateTime now,
    bool beginner = false,
    bool trainsFocus = false,
    double adherence = 1,
    ProgressionSettings settings = const ProgressionSettings(),
  }) {
    final goalRange = RepRange.forGoal(goal);
    final lastTop = history.last?.bestSet?.weightKg;

    ExerciseRecommendation build(CoachAction action, SetPrescription target, String badge, String reason) {
      final alt = _alternative(exercise, history, goal, goalRange, beginner, target);
      return ExerciseRecommendation(
        action: action,
        target: target,
        badge: badge,
        reason: reason,
        goal: goal,
        goalRange: goalRange,
        alternative: alt?.$1,
        alternativeReason: alt?.$2,
      );
    }

    final planned = ProgressionEngine.repRange(exercise.reps);
    if (planned == null) {
      return build(
        CoachAction.timed,
        SetPrescription(weightKg: exercise.targetKg ?? lastTop, sets: exercise.sets, reps: exercise.reps),
        'Beat last time',
        'This set is timed or taken near your limit. Aim to do a little more than last time with the same good form.',
      );
    }

    if (history.isEmpty) {
      return build(
        CoachAction.findWeight,
        SetPrescription(weightKg: exercise.targetKg, sets: exercise.sets, reps: exercise.reps),
        'First time',
        exercise.targetKg != null
            ? 'No sets logged yet. Start at your plan\'s target and stop with about 2 reps to spare.'
            : 'No sets logged yet. Pick a weight you could lift about 2 more times than the target, then log it.',
      );
    }

    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: ProgressionEngine.windowWeeks * 7));
    final recent = ExerciseHistory([
      for (final h in history.entries)
        if (!h.date.isBefore(from)) h
    ]);

    if (recent.isEmpty) {
      final eased = lastTop == null ? null : ProgressionEngine.roundKg(lastTop * 0.9);
      return build(
        CoachAction.easeOff,
        SetPrescription(weightKg: eased, sets: exercise.sets, reps: exercise.reps),
        'Ease back in',
        'It has been over ${ProgressionEngine.windowWeeks} weeks since you logged this. Start a little lighter.',
      );
    }

    final decision = ProgressionEngine.decideFor(
      exercise: exercise,
      history: recent,
      goal: goal,
      settings: settings,
      adherence: adherence,
      trainsFocus: trainsFocus,
    );
    final recentTop = recent.last!.bestSet?.weightKg;

    if (decision == null) {
      return build(
        CoachAction.hold,
        SetPrescription(weightKg: exercise.targetKg ?? recentTop, sets: exercise.sets, reps: exercise.reps),
        'Hold',
        'Not ready to move up yet. Repeat this and try to finish every set at ${planned.hi} reps.',
      );
    }

    final action = switch (decision.kind) {
      ChangeKind.load => CoachAction.addWeight,
      ChangeKind.reps => CoachAction.addReps,
      ChangeKind.sets => CoachAction.addSet,
      ChangeKind.deload => CoachAction.easeOff,
      ChangeKind.hold => CoachAction.hold,
    };
    final updated = decision.updated;
    final weight = decision.kind == ChangeKind.hold
        ? (decision.baseKg ?? recentTop)
        : (updated.targetKg ?? decision.baseKg ?? recentTop);
    return build(
      action,
      SetPrescription(weightKg: weight, sets: updated.sets, reps: updated.reps),
      decision.badge,
      decision.reason,
    );
  }

  /// The goal-range option, when the plan's reps sit outside it. The weight
  /// comes from an estimated one-rep max of the last top set, kept within 10% of
  /// what was lifted so a formula never asks for a big jump.
  static (SetPrescription, String)? _alternative(
    Exercise ex,
    ExerciseHistory history,
    GoalKind goal,
    RepRange range,
    bool beginner,
    SetPrescription target,
  ) {
    // Heavy low-rep work is not something to suggest to a beginner.
    if (beginner && goal == GoalKind.strength) return null;
    final planned = ProgressionEngine.repRange(ex.reps);
    if (planned == null || history.isEmpty) return null;
    final middle = (planned.lo + planned.hi) / 2;
    if (middle >= range.lo && middle <= range.hi) return null;

    final reps = middle > range.hi ? range.hi - (goal == GoalKind.strength ? 1 : 2) : range.lo + (goal == GoalKind.strength ? 2 : goal == GoalKind.fatLoss ? 0 : 2);
    final top = history.last!.bestSet;
    final w = top?.weightKg;
    final done = top?.reps;
    double? weight;
    if (w != null && w > 0 && done != null && done > 0) {
      final oneRepMax = w * (1 + done / 30);
      final raw = oneRepMax / (1 + reps / 30);
      weight = ProgressionEngine.roundKg(raw.clamp(w * 0.9, w * 1.1).toDouble());
    }
    final alt = SetPrescription(weightKg: weight, sets: target.sets, reps: '$reps');
    if (alt == target) return null;
    return (
      alt,
      'Your plan says ${ex.reps} reps. For ${goalName(goal)}, ${range.label} reps is the usual range.',
    );
  }
}
