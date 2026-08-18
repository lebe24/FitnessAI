import 'package:fitness/data/services/storage/active_plan_storage.dart';
import 'package:fitness/domain/models/stored_fitness_plan.dart';
import 'package:fitness/domain/models/workout_day_mapping.dart';
import 'package:fitness/domain/models/workout_streak.dart';
import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/domain/use_cases/fitness/get_user_data_usecase.dart';
import 'package:fitness/domain/use_cases/storage/get_all_fitness_plans_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FitnessViewModel extends ChangeNotifier {
  final GetAllFitnessPlansUsecase _getAllFitnessPlansUsecase;
  final GetUserDataUsecase? _getUserDataUsecase;
  final GetCurrentUser? _getCurrentUser;

  FitnessViewModel({
    required GetAllFitnessPlansUsecase getAllFitnessPlansUsecase,
    GetUserDataUsecase? getUserDataUsecase,
    GetCurrentUser? getCurrentUser,
  })  : _getAllFitnessPlansUsecase = getAllFitnessPlansUsecase,
        _getUserDataUsecase = getUserDataUsecase,
        _getCurrentUser = getCurrentUser;

  static const String _completedDatesBoxName = 'completed_workout_dates';
  static const String _streakKey = 'workout_streak';

  List<StoredFitnessPlanEntity> _plans = [];
  Map<DateTime, WorkoutDayMappingEntity> _workoutMappings = {};
  DateTime? _selectedDate;
  Set<DateTime> _completedDates = {};
  String? _activePlanId;
  int _streak = 0;
  bool _isLoading = false;
  String? _error;

  bool _disposed = false;

  List<StoredFitnessPlanEntity> get plans => _plans;
  Map<DateTime, WorkoutDayMappingEntity> get workoutMappings => _workoutMappings;
  DateTime? get selectedDate => _selectedDate;
  Set<DateTime> get completedDates => _completedDates;

  /// The program currently driving the home calendar.
  ///
  /// Resolves the stored id, falling back to the most recently created plan
  /// when nothing is stored or the stored plan has been deleted. The fallback
  /// is deliberately *newest*, not `plans.first` — Hive returns box key order,
  /// so first is arbitrary and was making the active program effectively
  /// random.
  StoredFitnessPlanEntity? get activePlan {
    if (_plans.isEmpty) return null;
    if (_activePlanId != null) {
      for (final p in _plans) {
        if (p.id == _activePlanId) return p;
      }
    }
    return _plans.reduce(
        (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
  }

  String? get activePlanId => activePlan?.id;

  bool isActive(StoredFitnessPlanEntity plan) => plan.id == activePlanId;
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
      _activePlanId = await ActivePlanStorage.load();
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

  /// Switch the user onto [plan] — the "reassign" action.
  ///
  /// Rebuilds the calendar mapping immediately so the home page reflects the
  /// new split without a reload. Nothing is deleted or regenerated; the other
  /// programs stay exactly as they were, so switching back is symmetrical.
  Future<void> setActivePlan(StoredFitnessPlanEntity plan) async {
    if (_disposed || plan.id == _activePlanId) return;
    _activePlanId = plan.id;
    await ActivePlanStorage.save(plan.id);
    _workoutMappings = _mapPlansToDates(_plans);
    if (!_disposed) notifyListeners();
  }

  /// Drop the pointer when the plan it names is removed, so [activePlan]
  /// falls back cleanly instead of resolving to nothing.
  Future<void> onPlanDeleted(String planId) async {
    if (planId != _activePlanId) return;
    _activePlanId = null;
    await ActivePlanStorage.clear();
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

    // Recompute from the session list rather than incrementing locally: the
    // session for this date may already be counted, and the server list is
    // what analytics shows.
    _streak = await _loadStreak();
    if (!_disposed) notifyListeners();
  }

  Map<DateTime, WorkoutDayMappingEntity> _mapPlansToDates(
      List<StoredFitnessPlanEntity> plans) {
    final Map<DateTime, WorkoutDayMappingEntity> mappings = {};
    if (plans.isEmpty) return mappings;

    final latestPlan = activePlan ?? plans.first;
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

  /// Derive the streak from completed sessions — the same source and the same
  /// calculation the analytics card uses.
  ///
  /// This previously read `current_streak` from the active workout_plan row,
  /// which the backend only refreshes when a session is patched to completed.
  /// Any other path to logging a workout left that column untouched, so the
  /// home badge drifted from analytics and stayed wrong. Computing from the
  /// session list removes the second source of truth entirely.
  Future<int> _loadStreak() async {
    final userId = _getCurrentUser?.call()?.id;
    if (userId != null && _getUserDataUsecase != null) {
      try {
        final rows = await _getUserDataUsecase(userId);
        final streak = WorkoutStreak.fromUserData(rows).days;
        await _saveStreak(streak);
        return streak;
      } catch (_) {
        // Offline or the sessions call failed — fall through to the cache.
      }
    }
    // Fallback: last known value, so the badge survives a cold start offline.
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
