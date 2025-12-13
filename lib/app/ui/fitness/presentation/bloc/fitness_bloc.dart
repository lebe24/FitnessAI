import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/storage/domain/usecases/get_all_fitness_plans_usecase.dart';
import 'package:fitness/app/ui/fitness/domain/entities/workout_day_mapping_entity.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_event.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_state.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FitnessBloc extends Bloc<FitnessEvent, FitnessState> {
  final GetAllFitnessPlansUsecase getAllFitnessPlansUsecase;

  FitnessBloc({
    required this.getAllFitnessPlansUsecase,
  }) : super(FitnessInitial()) {
    on<LoadFitnessPlans>(_onLoadFitnessPlans);
    on<DateSelected>(_onDateSelected);
  }

  Future<void> _onLoadFitnessPlans(
    LoadFitnessPlans event,
    Emitter<FitnessState> emit,
  ) async {
    emit(FitnessLoading());
    try {
      final plans = await getAllFitnessPlansUsecase();
      final workoutMappings = _mapPlansToDates(plans);
      emit(FitnessLoaded(
        plans: plans,
        workoutMappings: workoutMappings,
      ));
    } catch (e) {
      emit(FitnessError(e.toString()));
    }
  }

  void _onDateSelected(
    DateSelected event,
    Emitter<FitnessState> emit,
  ) {
    if (state is FitnessLoaded) {
      final currentState = state as FitnessLoaded;
      emit(currentState.copyWith(selectedDate: event.date));
    }
  }

  /// Maps workout plans to dates based on weekly split
  Map<DateTime, WorkoutDayMappingEntity> _mapPlansToDates(
    List<StoredFitnessPlanEntity> plans,
  ) {
    final Map<DateTime, WorkoutDayMappingEntity> mappings = {};

    // Use the most recent plan (first in the list as they're sorted by createdAt desc)
    if (plans.isEmpty) return mappings;

    final latestPlan = plans.first;
    final weeklySplit = latestPlan.workoutPlan.plan.weeklySplit;

    // Map each workout day to dates in the current week
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    for (var workoutDay in weeklySplit.days) {
      // Find the day of week (1 = Monday, 7 = Sunday)
      final dayOfWeek = _getDayOfWeekFromName(workoutDay.day);

      if (dayOfWeek != null) {
        // Calculate the date for this day in the current week
        final targetDate = startOfWeek.add(Duration(days: dayOfWeek - 1));

        // Also map to dates in the visible range (3 days before and after today)
        for (int weekOffset = -1; weekOffset <= 1; weekOffset++) {
          final date = targetDate.add(Duration(days: weekOffset * 7));
          final normalizedDate = DateTime(date.year, date.month, date.day);

          mappings[normalizedDate] = WorkoutDayMappingEntity(
            date: normalizedDate,
            workoutDay: workoutDay,
            planId: latestPlan.id,
          );
        }
      }
    }

    return mappings;
  }

  /// Converts day name to weekday number (1 = Monday, 7 = Sunday)
  int? _getDayOfWeekFromName(String dayName) {
    final normalizedName = dayName.toLowerCase().trim();
    final dayMap = {
      'monday': 1,
      'mon': 1,
      'tuesday': 2,
      'tue': 2,
      'wednesday': 3,
      'wed': 3,
      'thursday': 4,
      'thu': 4,
      'friday': 5,
      'fri': 5,
      'saturday': 6,
      'sat': 6,
      'sunday': 7,
      'sun': 7,
    };
    return dayMap[normalizedName];
  }
}

