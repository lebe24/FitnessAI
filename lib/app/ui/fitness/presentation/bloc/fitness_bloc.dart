import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/storage/domain/usecases/get_all_fitness_plans_usecase.dart';
import 'package:fitness/app/ui/fitness/domain/entities/workout_day_mapping_entity.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_event.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FitnessBloc extends Bloc<FitnessEvent, FitnessState> {
  final GetAllFitnessPlansUsecase getAllFitnessPlansUsecase;
  static const String _completedDatesBoxName = 'completed_workout_dates';
  static const String _streakKey = 'workout_streak';
  static const String _lastCompletedDateKey = 'last_completed_date';

  FitnessBloc({
    required this.getAllFitnessPlansUsecase,
  }) : super(FitnessInitial()) {
    on<LoadFitnessPlans>(_onLoadFitnessPlans);
    on<DateSelected>(_onDateSelected);
    on<WorkoutCompleted>(_onWorkoutCompleted);
  }

  Future<void> _onLoadFitnessPlans(
    LoadFitnessPlans event,
    Emitter<FitnessState> emit,
  ) async {
    emit(FitnessLoading());
    try {
      final plans = await getAllFitnessPlansUsecase();
      final workoutMappings = _mapPlansToDates(plans);
      final completedDates = await _loadCompletedDates();
      final streak = await _loadStreak();
      emit(FitnessLoaded(
        plans: plans,
        workoutMappings: workoutMappings,
        completedDates: completedDates.isNotEmpty ? completedDates : <DateTime>{},
        streak: streak,
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

  Future<void> _onWorkoutCompleted(
    WorkoutCompleted event,
    Emitter<FitnessState> emit,
  ) async {
    if (state is FitnessLoaded) {
      final currentState = state as FitnessLoaded;
      final normalizedDate = DateTime(event.date.year, event.date.month, event.date.day);
      
      // Check if already completed
      if (currentState.completedDates.contains(normalizedDate)) {
        return; // Already completed, don't increment streak again
      }

      // Add to completed dates
      final updatedCompletedDates = {...currentState.completedDates, normalizedDate};
      await _saveCompletedDates(updatedCompletedDates);

      // Calculate new streak
      final newStreak = await _calculateStreak(updatedCompletedDates);
      await _saveStreak(newStreak);

      // Update state
      emit(currentState.copyWith(
        completedDates: updatedCompletedDates.isNotEmpty ? updatedCompletedDates : <DateTime>{},
        streak: newStreak > 0 ? newStreak : 0,
      ));
    }
  }

  Future<Set<DateTime>> _loadCompletedDates() async {
    try {
      final box = await Hive.openBox(_completedDatesBoxName);
      final datesList = box.get('dates', defaultValue: <String>[]);
      if (datesList is List<dynamic>) {
        return datesList.map((dateStr) {
          if (dateStr is String) {
            final date = DateTime.parse(dateStr);
            // Normalize to just year/month/day for consistent comparison
            return DateTime(date.year, date.month, date.day);
          }
          return DateTime.now();
        }).toSet();
      }
      return <DateTime>{};
    } catch (e) {
      return <DateTime>{};
    }
  }

  Future<void> _saveCompletedDates(Set<DateTime> dates) async {
    try {
      final box = await Hive.openBox(_completedDatesBoxName);
      final datesList = dates.map((date) => date.toIso8601String()).toList();
      await box.put('dates', datesList);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<int> _loadStreak() async {
    try {
      final box = await Hive.openBox(_completedDatesBoxName);
      final value = box.get(_streakKey, defaultValue: 7);
      return value is int ? value : 4;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _saveStreak(int streak) async {
    try {
      final box = await Hive.openBox(_completedDatesBoxName);
      await box.put(_streakKey, streak);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<int> _calculateStreak(Set<DateTime> completedDates) async {
    if (completedDates.isEmpty) return 0;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    
    // Sort dates in descending order
    final sortedDates = completedDates.toList()..sort((a, b) => b.compareTo(a));
    
    if (sortedDates.isEmpty) return 0;
    
    final lastCompleted = sortedDates.first;
    final yesterday = normalizedToday.subtract(const Duration(days: 1));
    
    // Determine starting point for streak calculation
    DateTime startDate;
    if (completedDates.contains(normalizedToday)) {
      // If today is completed, count from today
      startDate = normalizedToday;
    } else if (lastCompleted == yesterday) {
      // If yesterday is completed but not today, count from yesterday
      startDate = yesterday;
    } else {
      // If last completed is more than 1 day ago, streak is broken
      return 0;
    }

    // Count consecutive days backwards from start date
    int streak = 0;
    DateTime checkDate = startDate;
    
    while (completedDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
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

