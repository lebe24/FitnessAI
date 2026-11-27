/// Draft shape of what the plan-update engine will hand to the UI.
///
/// Nothing produces these yet. They exist so the screens can be designed and
/// reviewed against realistic data before any logic is written; the engine
/// will be built to emit exactly this, or this will change to fit it.
library;

import 'package:fitness/domain/models/workout_plan.dart';

/// What an update does to one exercise.
enum ChangeKind {
  /// Heavier target load.
  load,

  /// More reps per set, same load.
  reps,

  /// An extra set.
  sets,

  /// A lighter week to recover from a stall.
  deload,

  /// Left as it is, with the reason.
  hold,
}

/// What the coach said about one proposed change.
enum CoachVerdict { approve, soften, veto }

/// Where the coach's review of a proposal stands.
enum CoachState {
  /// Not asked: the user is not on Pro, or the coach is not set up.
  off,

  /// The review is on its way.
  reviewing,

  /// Every change has been looked at.
  reviewed,

  /// The coach could not be reached or did not answer in time, so the changes
  /// stand as the rules proposed them.
  unavailable,
}

/// One exercise's before and after.
class PlannedChange {
  /// Short day name as shown on the plan: `Mon`.
  final String day;

  /// The day's focus: `Push`.
  final String dayFocus;
  final String exercise;
  final ChangeKind kind;

  /// `3 × 8–10 · 60 kg`
  final String before;

  /// `3 × 8–10 · 62.5 kg`
  final String after;

  /// The headline of the change: `+2.5 kg`, `+1 rep`, `+1 set`, `−10%`.
  final String badge;

  /// One plain sentence naming the data behind it.
  final String reason;

  /// Where the exercise sits in the plan's weekly split, and what it becomes
  /// when the change is applied. Absent on the design-review samples.
  final int dayIndex;
  final int exerciseIndex;
  final Exercise? updated;

  /// The weight the plan asked for before this change, when it had one.
  /// Easing a load change back works from this.
  final double? previousKg;

  /// What the coach decided, and the sentence they gave for it.
  final CoachVerdict? coachVerdict;
  final String? coachReason;

  const PlannedChange({
    required this.day,
    required this.dayFocus,
    required this.exercise,
    required this.kind,
    required this.before,
    required this.after,
    required this.badge,
    required this.reason,
    this.dayIndex = -1,
    this.exerciseIndex = -1,
    this.updated,
    this.previousKg,
    this.coachVerdict,
    this.coachReason,
  });

  bool get isHold => kind == ChangeKind.hold;

  /// True when the coach changed what the rules proposed.
  bool get coachAdjusted => coachVerdict == CoachVerdict.soften || coachVerdict == CoachVerdict.veto;

  /// This change as the coach reviewed it. [updated] is replaced as given,
  /// including with null, which is how a veto removes the change.
  PlannedChange reviewed({
    required CoachVerdict verdict,
    String? coachReason,
    ChangeKind? kind,
    String? after,
    String? badge,
    String? reason,
    Exercise? updated,
    bool clearUpdated = false,
  }) =>
      PlannedChange(
        day: day,
        dayFocus: dayFocus,
        exercise: exercise,
        kind: kind ?? this.kind,
        before: before,
        after: after ?? this.after,
        badge: badge ?? this.badge,
        reason: reason ?? this.reason,
        dayIndex: dayIndex,
        exerciseIndex: exerciseIndex,
        updated: clearUpdated ? null : (updated ?? this.updated),
        previousKg: previousKg,
        coachVerdict: verdict,
        coachReason: coachReason,
      );
}

/// A full proposed update to the active plan.
class ProgressionProposal {
  final String planName;
  final String goal;
  final int fromVersion;
  final int toVersion;

  /// The window the history was read from.
  final int weeks;
  final int sessionsAnalysed;

  /// Share of planned sessions that were done, 0–1.
  final double adherence;
  final int newPersonalBests;

  /// True when the update is a lighter recovery week.
  final bool isDeload;
  final List<PlannedChange> changes;

  /// The coach's review of these changes.
  final CoachState coachState;

  /// One or two sentences from the coach about the update as a whole.
  final String? coachNote;

  const ProgressionProposal({
    required this.planName,
    required this.goal,
    required this.fromVersion,
    required this.toVersion,
    required this.weeks,
    required this.sessionsAnalysed,
    required this.adherence,
    required this.newPersonalBests,
    required this.isDeload,
    required this.changes,
    this.coachState = CoachState.off,
    this.coachNote,
  });

  ProgressionProposal withCoach({
    List<PlannedChange>? changes,
    required CoachState state,
    String? note,
  }) =>
      ProgressionProposal(
        planName: planName,
        goal: goal,
        fromVersion: fromVersion,
        toVersion: toVersion,
        weeks: weeks,
        sessionsAnalysed: sessionsAnalysed,
        adherence: adherence,
        newPersonalBests: newPersonalBests,
        isDeload: isDeload,
        changes: changes ?? this.changes,
        coachState: state,
        coachNote: note,
      );

  Iterable<PlannedChange> get actionable => changes.where((c) => !c.isHold);
  int get holdCount => changes.where((c) => c.isHold).length;
}

/// How eagerly the engine adds load.
enum ProgressionPace { steady, balanced, ambitious }

/// How often the engine looks at the history.
enum ProgressionCadence { weekly, fortnightly, monthly }

/// What happens once an update is ready.
enum ApplyMode { review, automatic }

/// An update that was applied earlier.
class AppliedUpdate {
  final int version;
  final DateTime date;
  final int changeCount;

  /// Two or three of the biggest changes, ready to show.
  final List<String> highlights;
  final bool wasAutomatic;
  final bool isDeload;

  /// The split as it was before this update, so it can be undone.
  final WeeklySplit? previous;

  const AppliedUpdate({
    required this.version,
    required this.date,
    required this.changeCount,
    required this.highlights,
    this.wasAutomatic = false,
    this.isDeload = false,
    this.previous,
  });
}

/// What the user chose for smart updates.
class ProgressionSettings {
  final bool enabled;
  final ApplyMode mode;
  final ProgressionCadence cadence;
  final ProgressionPace pace;
  final bool deloads;

  const ProgressionSettings({
    this.enabled = true,
    this.mode = ApplyMode.review,
    this.cadence = ProgressionCadence.weekly,
    this.pace = ProgressionPace.balanced,
    this.deloads = true,
  });

  ProgressionSettings copyWith({
    bool? enabled,
    ApplyMode? mode,
    ProgressionCadence? cadence,
    ProgressionPace? pace,
    bool? deloads,
  }) =>
      ProgressionSettings(
        enabled: enabled ?? this.enabled,
        mode: mode ?? this.mode,
        cadence: cadence ?? this.cadence,
        pace: pace ?? this.pace,
        deloads: deloads ?? this.deloads,
      );

  /// Days between looks at the history.
  int get intervalDays => switch (cadence) {
        ProgressionCadence.weekly => 7,
        ProgressionCadence.fortnightly => 14,
        ProgressionCadence.monthly => 30,
      };
}

/// Where the card on the programs screen stands.
enum ProgressionStatus { ready, building, upToDate, off }
