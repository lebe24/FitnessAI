import 'package:equatable/equatable.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/goal_progress.dart';
import 'package:fitness/domain/body/muscle_focus.dart';

class AdviceAction extends Equatable {
  final String title;
  final String detail;
  const AdviceAction({required this.title, required this.detail});

  @override
  List<Object?> get props => [title, detail];
}

/// Advice on the body goal, with the figures it was written around.
class BodyAdvice extends Equatable {
  final ProgressStatus status;
  final String headline;
  final String summary;
  final List<AdviceAction> actions;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final double? weeklyChangeKg;
  final double? plannedRateKg;
  final double? projectedWeeks;
  final int? calorieAdjustmentKcal;
  final String disclaimer;
  final DateTime generatedAt;

  /// True when the AI wrote it; false for the fixed wording used when it could not.
  final bool fromModel;
  final bool cached;

  const BodyAdvice({
    required this.status,
    required this.headline,
    required this.summary,
    required this.actions,
    required this.disclaimer,
    required this.generatedAt,
    this.currentWeightKg,
    this.targetWeightKg,
    this.weeklyChangeKg,
    this.plannedRateKg,
    this.projectedWeeks,
    this.calorieAdjustmentKcal,
    this.fromModel = true,
    this.cached = false,
  });

  @override
  List<Object?> get props => [status, headline, summary, actions, generatedAt, fromModel, cached];
}

/// What the device tells the advisor about training. The figures are the ones
/// on the analytics screen, so the advice cannot disagree with it.
class AdviceRequest {
  final int sessionsLogged;
  final double workoutsPerWeek;
  final double volumeLast28DaysKg;
  final int streakDays;
  final List<MuscleStatus> muscles;
  final bool forceRefresh;

  const AdviceRequest({
    required this.sessionsLogged,
    required this.workoutsPerWeek,
    required this.volumeLast28DaysKg,
    required this.streakDays,
    required this.muscles,
    this.forceRefresh = false,
  });
}

enum BodyTrackingError { premiumRequired, rateLimited, offline, server }

class BodyTrackingException implements Exception {
  final BodyTrackingError error;
  final String message;
  const BodyTrackingException(this.error, [this.message = '']);

  @override
  String toString() => 'BodyTrackingException($error) $message';
}

/// Everything saved about the user's body, on the device and (once synced) on
/// the server.
class BodySnapshot {
  final FitnessGoal? goal;

  /// Oldest first, one per day.
  final List<BodyWeightEntry> weights;

  /// Oldest first.
  final List<BodyMeasurement> measurements;

  /// Written on the device and not yet confirmed by the server.
  final List<BodyWeightEntry> pendingWeights;
  final List<BodyMeasurement> pendingMeasurements;
  final bool goalPending;

  /// Whether the old single-value weight has already been turned into a log entry.
  final bool legacySeeded;

  /// Who this copy belongs to. A copy made by another account is discarded,
  /// so one person's entries are never sent to another's.
  final String? ownerId;

  const BodySnapshot({
    this.goal,
    this.weights = const [],
    this.measurements = const [],
    this.pendingWeights = const [],
    this.pendingMeasurements = const [],
    this.goalPending = false,
    this.legacySeeded = false,
    this.ownerId,
  });

  static const empty = BodySnapshot();

  bool get hasPending =>
      goalPending || pendingWeights.isNotEmpty || pendingMeasurements.isNotEmpty;

  BodySnapshot copyWith({
    FitnessGoal? goal,
    bool clearGoal = false,
    List<BodyWeightEntry>? weights,
    List<BodyMeasurement>? measurements,
    List<BodyWeightEntry>? pendingWeights,
    List<BodyMeasurement>? pendingMeasurements,
    bool? goalPending,
    bool? legacySeeded,
    String? ownerId,
  }) =>
      BodySnapshot(
        goal: clearGoal ? null : (goal ?? this.goal),
        weights: weights ?? this.weights,
        measurements: measurements ?? this.measurements,
        pendingWeights: pendingWeights ?? this.pendingWeights,
        pendingMeasurements: pendingMeasurements ?? this.pendingMeasurements,
        goalPending: goalPending ?? this.goalPending,
        legacySeeded: legacySeeded ?? this.legacySeeded,
        ownerId: ownerId ?? this.ownerId,
      );
}
