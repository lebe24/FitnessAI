import 'package:fitness/data/services/storage/workout_plan_sync_service.dart';
import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/models/workout_day_mapping.dart';
import 'package:fitness/domain/use_cases/storage/get_all_fitness_plans_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FitnessViewModel extends ChangeNotifier {
  final GetAllFitnessPlansUsecase _getAllFitnessPlansUsecase;
  final WorkoutPlanSyncDataSource? _planSyncDataSource;

  FitnessViewModel({
    required GetAllFitnessPlansUsecase getAllFitnessPlansUsecase,
    WorkoutPlanSyncDataSource? planSyncDataSource,
  })  : _getAllFitnessPlansUsecase = getAllFitnessPlansUsecase,
        _planSyncDataSource = planSyncDataSource;

  static const String _completedDatesBoxName = 'completed_workout_dates';
  static const String _streakKey = 'workout_streak';

  List<StoredFitnessPlanEntity> _plans = [];
  Map<DateTime, WorkoutDayMappingEntity> _workoutMappings = {};
  DateTime? _selectedDate;
  Set<DateTime> _completedDates = {};
  int _streak = 0;
  bool _isLoading = false;
  String? _error;

  bool _disposed = false;

  List<StoredFitnessPlanEntity> get plans => _plans;
  Map<DateTime, WorkoutDayMappingEntity> get workoutMappings => _workoutMappings;
  DateTime? get selectedDate => _selectedDate;
  Set<DateTime> get completedDates => _completedDates;
  int get streak => _streak;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadFitnessPlans() async {
    if (_disposed) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _plans = await _getAllFitnessPlansUsecase();
      _workoutMappings = _mapPlansToDates(_plans);
      _completedDates = await _loadCompletedDates();
      _streak = await _loadStreak();
    } catch (e, st) {
      debugPrint('FitnessViewModel: $e\n$st');
      _error = e.toString();
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void selectDate(DateTime date) {
    if (_disposed) return;
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> completeWorkout(DateTime date, {int durationMins = 0}) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Update local completed-dates cache immediately so the calendar UI reacts.
    if (!_completedDates.contains(normalizedDate)) {
      final updated = <DateTime>{..._completedDates, normalizedDate};
      await _saveCompletedDates(updated);
      _completedDates = updated;
    }

    // The backend already wrote current_streak to the active plan row when the
    // session was patched to completed. Read it back as the authoritative value.
    _streak = await _loadStreak();
    if (!_disposed) notifyListeners();
  }

  Map<DateTime, WorkoutDayMappingEntity> _mapPlansToDates(
      List<StoredFitnessPlanEntity> plans) {
    final Map<DateTime, WorkoutDayMappingEntity> mappings = {};
    if (plans.isEmpty) return mappings;

    final latestPlan = plans.first;
    final weeklySplit = latestPlan.workoutPlan.plan.weeklySplit;
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    for (var workoutDay in weeklySplit.days) {
      final dayOfWeek = _dayOfWeekFromName(workoutDay.day);
      if (dayOfWeek != null) {
        for (int weekOffset = -1; weekOffset <= 1; weekOffset++) {
          final targetDate = startOfWeek.add(Duration(days: dayOfWeek - 1));
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

  int? _dayOfWeekFromName(String name) {
    const map = {
      'monday': 1, 'mon': 1,
      'tuesday': 2, 'tue': 2,
      'wednesday': 3, 'wed': 3,
      'thursday': 4, 'thu': 4,
      'friday': 5, 'fri': 5,
      'saturday': 6, 'sat': 6,
      'sunday': 7, 'sun': 7,
    };
    return map[name.toLowerCase().trim()];
  }

  Future<Set<DateTime>> _loadCompletedDates() async {
    try {
      final box = await Hive.openBox(_completedDatesBoxName);
      final datesList = box.get('dates', defaultValue: <String>[]);
      if (datesList is List<dynamic>) {
        return datesList.map((d) {
          final parsed = DateTime.parse(d as String);
          return DateTime(parsed.year, parsed.month, parsed.day);
        }).toSet();
      }
    } catch (e) {
      debugPrint('FitnessViewModel: error loading dates: $e');
    }
    return {};
  }

  Future<void> _saveCompletedDates(Set<DateTime> dates) async {
    try {
      final box = await Hive.openBox(_completedDatesBoxName);
      await box.put('dates', dates.map((d) => d.toIso8601String()).toList());
      await box.flush();
    } catch (e) {
      debugPrint('FitnessViewModel: error saving dates: $e');
    }
  }

  Future<int> _loadStreak() async {
    // Primary: read current_streak from the active workout_plan row in the DB.
    if (_planSyncDataSource != null) {
      try {
        final s = await _planSyncDataSource.getStreakFromPlan();
        await _saveStreak(s.current);
        return s.current;
      } catch (_) {
        // Fall through to Hive cache.
      }
    }
    // Fallback: local Hive cache (no network).
    try {
      final box = await Hive.openBox(_completedDatesBoxName);
      final value = box.get(_streakKey, defaultValue: 0);
      return value is int ? value : 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _saveStreak(int streak) async {
    try {
      final box = await Hive.openBox(_completedDatesBoxName);
      await box.put(_streakKey, streak);
      await box.flush();
    } catch (e) {
      debugPrint('FitnessViewModel: error saving streak: $e');
    }
  }

}
