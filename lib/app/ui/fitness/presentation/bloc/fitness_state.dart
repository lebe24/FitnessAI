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
  final Set<DateTime> completedDates;
  final int streak;

  const FitnessLoaded({
    required this.plans,
    required this.workoutMappings,
    this.selectedDate,
    this.completedDates = const {},
    this.streak = 2
  });

  FitnessLoaded copyWith({
    List<StoredFitnessPlanEntity>? plans,
    Map<DateTime, WorkoutDayMappingEntity>? workoutMappings,
    DateTime? selectedDate,
    Set<DateTime>? completedDates,
    int? streak,
  }) {
    return FitnessLoaded(
      plans: plans ?? this.plans,
      workoutMappings: workoutMappings ?? this.workoutMappings,
      selectedDate: selectedDate ?? this.selectedDate,
      completedDates: completedDates ?? this.completedDates,
      streak: streak ?? this.streak,
    );
  }

  @override
  List<Object?> get props => [plans, workoutMappings, selectedDate, completedDates, streak];
}

class FitnessError extends FitnessState {
  final String message;

  const FitnessError(this.message);

  @override
  List<Object?> get props => [message];
}

