import 'package:equatable/equatable.dart';
import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/ui/fitness/domain/entities/workout_day_mapping_entity.dart';

abstract class FitnessState extends Equatable {
  const FitnessState();

  @override
  List<Object?> get props => [];
}

class FitnessInitial extends FitnessState {}

class FitnessLoading extends FitnessState {}

class FitnessLoaded extends FitnessState {
  final List<StoredFitnessPlanEntity> plans;
  final Map<DateTime, WorkoutDayMappingEntity> workoutMappings;
  final DateTime? selectedDate;

  const FitnessLoaded({
    required this.plans,
    required this.workoutMappings,
    this.selectedDate,
  });

  FitnessLoaded copyWith({
    List<StoredFitnessPlanEntity>? plans,
    Map<DateTime, WorkoutDayMappingEntity>? workoutMappings,
    DateTime? selectedDate,
  }) {
    return FitnessLoaded(
      plans: plans ?? this.plans,
      workoutMappings: workoutMappings ?? this.workoutMappings,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  @override
  List<Object?> get props => [plans, workoutMappings, selectedDate];
}

class FitnessError extends FitnessState {
  final String message;

  const FitnessError(this.message);

  @override
  List<Object?> get props => [message];
}

