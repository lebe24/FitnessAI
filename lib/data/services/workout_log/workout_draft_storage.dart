import 'package:fitness/domain/models/workout_plan.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// One logged set inside a draft — the raw text the user typed, kept as
/// strings so a half-filled field ("12", "") round-trips exactly.
class DraftSet {
  final String weight;
  final String reps;
  const DraftSet({this.weight = '', this.reps = ''});

  bool get isEmpty => weight.trim().isEmpty && reps.trim().isEmpty;

  Map<String, dynamic> toMap() => {'weight': weight, 'reps': reps};

  static DraftSet fromMap(Map m) => DraftSet(
        weight: m['weight'] as String? ?? '',
        reps: m['reps'] as String? ?? '',
      );
}

/// An in-progress workout that has not been pushed to Supabase yet.
///
/// Survives the app being killed: the user can start a workout, close the
/// app mid-session, and come back to the same completed exercises, order,
/// and logged sets.
class WorkoutDraft {
  final String dateKey; // yyyy-MM-dd — one draft per workout day
  final String? dayLabel;
  final List<Exercise> exercises; // preserves user reordering + additions
  final Set<int> completed;
  final int currentIndex;
  final List<DateTime> completionTimestamps;

  /// Logged sets keyed by exercise name. Name-keyed rather than index-keyed
  /// so reordering the list can't misattribute someone's logged weights.
  final Map<String, List<DraftSet>> setLogs;

  const WorkoutDraft({
    required this.dateKey,
    this.dayLabel,
    this.exercises = const [],
    this.completed = const {},
    this.currentIndex = 0,
    this.completionTimestamps = const [],
    this.setLogs = const {},
  });

  bool get isEmpty =>
      completed.isEmpty && setLogs.isEmpty && completionTimestamps.isEmpty;

  WorkoutDraft copyWith({
    List<Exercise>? exercises,
    Set<int>? completed,
    int? currentIndex,
    List<DateTime>? completionTimestamps,
    Map<String, List<DraftSet>>? setLogs,
  }) =>
      WorkoutDraft(
        dateKey: dateKey,
        dayLabel: dayLabel,
        exercises: exercises ?? this.exercises,
        completed: completed ?? this.completed,
        currentIndex: currentIndex ?? this.currentIndex,
        completionTimestamps: completionTimestamps ?? this.completionTimestamps,
        setLogs: setLogs ?? this.setLogs,
      );

  Map<String, dynamic> toMap() => {
        'dateKey': dateKey,
        'dayLabel': dayLabel,
        'exercises': exercises
            .map((e) => {
                  'name': e.name,
                  'sets': e.sets,
                  'reps': e.reps,
                  'notes': e.notes,
                })
            .toList(),
        'completed': completed.toList(),
        'currentIndex': currentIndex,
        'timestamps':
            completionTimestamps.map((d) => d.toIso8601String()).toList(),
        'setLogs': setLogs.map(
            (name, sets) => MapEntry(name, sets.map((s) => s.toMap()).toList())),
      };

  static WorkoutDraft fromMap(Map m) => WorkoutDraft(
        dateKey: m['dateKey'] as String,
        dayLabel: m['dayLabel'] as String?,
        exercises: ((m['exercises'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Exercise(
                  name: e['name'] as String? ?? '',
                  sets: (e['sets'] as num?)?.toInt() ?? 3,
                  reps: e['reps'] as String? ?? '',
                  notes: e['notes'] as String?,
                ))
            .toList(),
        completed: ((m['completed'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toSet(),
        currentIndex: (m['currentIndex'] as num?)?.toInt() ?? 0,
        completionTimestamps: ((m['timestamps'] as List?) ?? const [])
            .whereType<String>()
            .map(DateTime.tryParse)
            .whereType<DateTime>()
            .toList(),
        setLogs: ((m['setLogs'] as Map?) ?? const {}).map(
          (name, sets) => MapEntry(
            name as String,
            ((sets as List?) ?? const [])
                .whereType<Map>()
                .map(DraftSet.fromMap)
                .toList(),
          ),
        ),
      );
}

/// Hive-backed store for in-progress workouts.
///
/// A draft is written on every meaningful change (exercise completed,
/// reordered, added, sets logged) and deleted **only** once the session has
/// been successfully pushed to Supabase — so a failed upload keeps the user's
/// work rather than silently discarding it.
class WorkoutDraftStorage {
  static const String boxName = 'workout_drafts';

  static Future<Box> _box() async => Hive.isBoxOpen(boxName)
      ? Hive.box(boxName)
      : await Hive.openBox(boxName);

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<void> save(WorkoutDraft draft) async {
    try {
      final box = await _box();
      await box.put(draft.dateKey, draft.toMap());
    } catch (e) {
      // Persistence is best-effort: never break the workout over a write.
      debugPrint('WorkoutDraftStorage.save failed: $e');
    }
  }

  static Future<WorkoutDraft?> load(DateTime date) async {
    try {
      final box = await _box();
      final raw = box.get(dateKey(date));
      if (raw is! Map) return null;
      return WorkoutDraft.fromMap(raw);
    } catch (e) {
      debugPrint('WorkoutDraftStorage.load failed: $e');
      return null;
    }
  }

  /// Called once the session reaches Supabase — this is the only place a
  /// draft is discarded.
  static Future<void> clear(DateTime date) async {
    try {
      final box = await _box();
      await box.delete(dateKey(date));
    } catch (e) {
      debugPrint('WorkoutDraftStorage.clear failed: $e');
    }
  }
}
