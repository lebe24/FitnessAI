import 'package:fitness/domain/models/workout_log.dart';

class SetEntryModel extends SetEntry {
  const SetEntryModel({
    required super.setNumber,
    required super.reps,
    super.weightKg,
    super.completed,
    super.rpe,
    super.notes,
  });

  factory SetEntryModel.fromJson(Map<String, dynamic> j) => SetEntryModel(
        setNumber: j['set_number'] as int,
        reps: j['reps'] as int,
        weightKg: (j['weight_kg'] as num?)?.toDouble() ?? 0,
        completed: j['completed'] as bool? ?? true,
        rpe: (j['rpe'] as num?)?.toDouble(),
        notes: j['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'set_number': setNumber,
        'reps': reps,
        'weight_kg': weightKg,
        'completed': completed,
        if (rpe != null) 'rpe': rpe,
        if (notes != null) 'notes': notes,
      };
}

class ExerciseLogModel extends ExerciseLogEntity {
  const ExerciseLogModel({
    super.id,
    super.sessionId,
    required super.exerciseName,
    super.muscleGroup,
    super.equipment,
    super.orderIndex,
    required super.sets,
    super.totalSets,
    super.completedSets,
    super.totalVolumeKg,
    super.notes,
    super.loggedAt,
  });

  factory ExerciseLogModel.fromJson(Map<String, dynamic> j) => ExerciseLogModel(
        id: j['id'] as String?,
        sessionId: j['session_id'] as String?,
        exerciseName: j['exercise_name'] as String,
        muscleGroup: j['muscle_group'] as String?,
        equipment: j['equipment'] as String?,
        orderIndex: j['order_index'] as int? ?? 0,
        sets: (j['sets'] as List<dynamic>? ?? [])
            .map((s) => SetEntryModel.fromJson(s as Map<String, dynamic>))
            .toList(),
        totalSets: j['total_sets'] as int?,
        completedSets: j['completed_sets'] as int?,
        totalVolumeKg: (j['total_volume_kg'] as num?)?.toDouble(),
        notes: j['notes'] as String?,
        loggedAt: j['logged_at'] != null
            ? DateTime.parse(j['logged_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'exercise_name': exerciseName,
        if (muscleGroup != null) 'muscle_group': muscleGroup,
        if (equipment != null) 'equipment': equipment,
        'order_index': orderIndex,
        'sets': sets.map((s) => (s as SetEntryModel).toJson()).toList(),
        if (notes != null) 'notes': notes,
      };
}

class WorkoutSessionModel extends WorkoutSessionEntity {
  const WorkoutSessionModel({
    super.id,
    required super.sessionDate,
    super.dayLabel,
    super.workoutPlanId,
    super.isCompleted,
    super.durationMins,
    super.notes,
    super.startedAt,
    super.completedAt,
    super.exerciseLogs,
  });

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> j) =>
      WorkoutSessionModel(
        id: j['id'] as String?,
        sessionDate: DateTime.parse(j['session_date'] as String),
        dayLabel: j['day_label'] as String?,
        workoutPlanId: j['workout_plan_id'] as String?,
        isCompleted: j['is_completed'] as bool? ?? false,
        durationMins: j['duration_mins'] as int?,
        notes: j['notes'] as String?,
        startedAt: j['started_at'] != null
            ? DateTime.parse(j['started_at'] as String)
            : null,
        completedAt: j['completed_at'] != null
            ? DateTime.parse(j['completed_at'] as String)
            : null,
      );

  Map<String, dynamic> toCreateJson() => {
        'session_date':
            '${sessionDate.year}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}',
        if (dayLabel != null) 'day_label': dayLabel,
        if (workoutPlanId != null) 'workout_plan_id': workoutPlanId,
        if (notes != null) 'notes': notes,
      };
}

/// Lightweight exercise entry for the single-row session save.
class ExerciseEntryModel {
  final String name;
  final int sets;
  final String reps;
  final String? notes;
  final String? muscleGroup;
  final String? equipment;
  final int orderIndex;

  const ExerciseEntryModel({
    required this.name,
    required this.sets,
    required this.reps,
    this.notes,
    this.muscleGroup,
    this.equipment,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        if (notes != null) 'notes': notes,
        if (muscleGroup != null) 'muscle_group': muscleGroup,
        if (equipment != null) 'equipment': equipment,
        'order_index': orderIndex,
      };
}

class WorkoutStreakModel extends WorkoutStreak {
  const WorkoutStreakModel({
    required super.currentStreak,
    required super.longestStreak,
    super.lastSession,
  });

  factory WorkoutStreakModel.fromJson(Map<String, dynamic> j) =>
      WorkoutStreakModel(
        currentStreak: j['current_streak'] as int? ?? 0,
        longestStreak: j['longest_streak'] as int? ?? 0,
        lastSession: j['last_session'] as String?,
      );
}
