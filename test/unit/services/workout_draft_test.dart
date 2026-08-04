import 'package:fitness/data/services/workout_log/workout_draft_storage.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WorkoutDraft survives a serialization round-trip', () {
    final original = WorkoutDraft(
      dateKey: '2026-07-27',
      dayLabel: 'Tuesday',
      exercises: const [
        Exercise(name: 'Squats', sets: 5, reps: '5-8', notes: 'deep'),
        Exercise(name: 'Leg Press', sets: 4, reps: '10-15'),
      ],
      completed: {0},
      currentIndex: 1,
      completionTimestamps: [DateTime.parse('2026-07-27T10:30:00Z')],
      setLogs: {
        'Squats': const [DraftSet(weight: '80', reps: '8'), DraftSet(weight: '85', reps: '5')],
      },
    );

    final restored = WorkoutDraft.fromMap(original.toMap());

    expect(restored.dateKey, '2026-07-27');
    expect(restored.dayLabel, 'Tuesday');
    expect(restored.exercises.length, 2);
    expect(restored.exercises[0].name, 'Squats');
    expect(restored.exercises[0].sets, 5);
    expect(restored.exercises[1].notes, isNull);
    expect(restored.completed, {0});
    expect(restored.currentIndex, 1);
    expect(restored.completionTimestamps.first.toUtc().hour, 10);
    expect(restored.setLogs['Squats']!.length, 2);
    expect(restored.setLogs['Squats']![0].weight, '80');
    expect(restored.setLogs['Squats']![1].reps, '5');
  });

  test('empty draft is detected so a stale entry never shows a resume toast', () {
    expect(const WorkoutDraft(dateKey: '2026-07-27').isEmpty, isTrue);
    expect(
      WorkoutDraft(dateKey: '2026-07-27', completed: const {1}).isEmpty,
      isFalse,
    );
  });
}
