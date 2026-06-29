import 'package:equatable/equatable.dart';
import 'package:fitness/domain/models/workout_plan.dart';

/// Entity representing a workout day mapped to a specific date
class WorkoutDayMappingEntity extends Equatable {
  final DateTime date;
  final WorkoutDay? workoutDay;
  final String? planId; // ID of the stored fitness plan

  const WorkoutDayMappingEntity({
    required this.date,
    this.workoutDay,
    this.planId,
  });

  bool get hasWorkout => workoutDay != null;

  @override
  List<Object?> get props => [date, workoutDay, planId];
}

