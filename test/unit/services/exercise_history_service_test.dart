import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/workout_log/exercise_history_service.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSessionModel squat(int day, int kg) => WorkoutSessionModel(
      sessionDate: DateTime(2026, 10, day),
      workoutLogs: [
        {'name': 'Squat', 'sets': 3, 'reps': '5', 'notes': 'set 1: 5 reps @ ${kg}kg'},
      ],
    );

void main() {
  late int fetches;
  late DateTime clock;
  late List<WorkoutSessionModel>? answer;
  late ExerciseHistoryService service;

  setUp(() {
    fetches = 0;
    clock = DateTime(2026, 10, 24, 12);
    answer = [squat(20, 90), squat(17, 85)];
    service = ExerciseHistoryService(
      fetch: () async {
        fetches++;
        return answer;
      },
      ttl: const Duration(minutes: 2),
      now: () => clock,
    );
  });

  test('answers from the sessions it reads', () async {
    final h = await service.load('Squat');
    expect(h!.length, 2);
    expect(h.last!.sets.single.weightKg, 90);
  });

  test('one workout asking for several exercises reads the sessions once', () async {
    await service.load('Squat');
    await service.load('Bench Press');
    await service.load('Deadlift');
    expect(fetches, 1);
  });

  test('simultaneous requests share a single read', () async {
    await Future.wait([service.load('Squat'), service.load('Squat'), service.load('Squat')]);
    expect(fetches, 1);
  });

  test('reads again once the cached sessions are stale', () async {
    await service.load('Squat');
    clock = clock.add(const Duration(minutes: 3));
    await service.load('Squat');
    expect(fetches, 2);
  });

  test('still uses the cache just inside the lifetime', () async {
    await service.load('Squat');
    clock = clock.add(const Duration(minutes: 1, seconds: 59));
    await service.load('Squat');
    expect(fetches, 1);
  });

  test('invalidate makes the next call read fresh — a new log shows up', () async {
    await service.load('Squat');
    answer = [squat(24, 95), ...answer!];
    service.invalidate();
    final h = await service.load('Squat');
    expect(fetches, 2);
    expect(h!.last!.sets.single.weightKg, 95);
  });

  test('null means the sessions could not be read, not that there is no history', () async {
    answer = null;
    expect(await service.load('Squat'), isNull);
  });

  test('a failed read is not cached — the next call tries again', () async {
    answer = null;
    await service.load('Squat');
    answer = [squat(20, 90)];
    final h = await service.load('Squat');
    expect(h!.length, 1);
    expect(fetches, 2);
  });

  test('an exception in the read comes back as null, not a crash', () async {
    final throwing = ExerciseHistoryService(fetch: () async => throw StateError('offline'));
    expect(await throwing.load('Squat'), isNull);
  });

  test('an exercise that was never logged is empty, not null', () async {
    final h = await service.load('Deadlift');
    expect(h, isNotNull);
    expect(h!.isEmpty, isTrue);
  });
}
