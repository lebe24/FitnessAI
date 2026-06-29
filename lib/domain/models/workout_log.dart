// Domain entities for workout sessions and exercise logs.

class SetEntry {
  final int setNumber;
  final int reps;
  final double weightKg;
  final bool completed;
  final double? rpe;
  final String? notes;

  const SetEntry({
    required this.setNumber,
    required this.reps,
    this.weightKg = 0,
    this.completed = true,
    this.rpe,
    this.notes,
  });
}

class ExerciseLogEntity {
  final String? id;
  final String? sessionId;
  final String exerciseName;
  final String? muscleGroup;
  final String? equipment;
  final int orderIndex;
  final List<SetEntry> sets;
  final int? totalSets;
  final int? completedSets;
  final double? totalVolumeKg;
  final String? notes;
  final DateTime? loggedAt;

  const ExerciseLogEntity({
    this.id,
    this.sessionId,
    required this.exerciseName,
    this.muscleGroup,
    this.equipment,
    this.orderIndex = 0,
    required this.sets,
    this.totalSets,
    this.completedSets,
    this.totalVolumeKg,
    this.notes,
    this.loggedAt,
  });
}

class WorkoutSessionEntity {
  final String? id;
  final DateTime sessionDate;
  final String? dayLabel;
  final String? workoutPlanId;
  final bool isCompleted;
  final int? durationMins;
  final String? notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<ExerciseLogEntity> exerciseLogs;

  const WorkoutSessionEntity({
    this.id,
    required this.sessionDate,
    this.dayLabel,
    this.workoutPlanId,
    this.isCompleted = false,
    this.durationMins,
    this.notes,
    this.startedAt,
    this.completedAt,
    this.exerciseLogs = const [],
  });

  WorkoutSessionEntity copyWith({
    String? id,
    DateTime? sessionDate,
    String? dayLabel,
    String? workoutPlanId,
    bool? isCompleted,
    int? durationMins,
    String? notes,
    DateTime? startedAt,
    DateTime? completedAt,
    List<ExerciseLogEntity>? exerciseLogs,
  }) {
    return WorkoutSessionEntity(
      id: id ?? this.id,
      sessionDate: sessionDate ?? this.sessionDate,
      dayLabel: dayLabel ?? this.dayLabel,
      workoutPlanId: workoutPlanId ?? this.workoutPlanId,
      isCompleted: isCompleted ?? this.isCompleted,
      durationMins: durationMins ?? this.durationMins,
      notes: notes ?? this.notes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
    );
  }
}

class ExerciseProgressEntry {
  final String exerciseName;
  final List<ExerciseLogEntity> history;

  const ExerciseProgressEntry({
    required this.exerciseName,
    required this.history,
  });
}

class WorkoutStreak {
  final int currentStreak;
  final int longestStreak;
  final String? lastSession;

  const WorkoutStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastSession,
  });
}
