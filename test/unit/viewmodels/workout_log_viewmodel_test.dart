import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/domain/models/workout_log.dart';
import 'package:fitness/ui/features/fitness/view_models/workout_log_view_model.dart';
import '../../fakes/fake_workout_log_repository.dart';
import '../../fixtures/fixtures.dart';

void main() {
  late FakeWorkoutLogRepository repo;
  late WorkoutLogViewModel vm;

  setUp(() {
    repo = FakeWorkoutLogRepository();
    vm = WorkoutLogViewModel(repo);
  });

  tearDown(() => vm.dispose());

  // ── startSession ────────────────────────────────────────────────────────────

  group('startSession', () {
    test('sets activeSession and status=success on success', () async {
      await vm.startSession(date: Fixtures.kDate, dayLabel: 'Day 1 – Push');

      expect(vm.status, WorkoutLogStatus.success);
      expect(vm.activeSession, isNotNull);
      expect(vm.activeSession!.id, 'sess-001');
      expect(vm.activeSession!.isCompleted, false);
    });

    test('sets status=error and keeps activeSession null when repo throws',
        () async {
      repo.createSessionError = Exception('network error');
      await vm.startSession(date: Fixtures.kDate);

      expect(vm.status, WorkoutLogStatus.error);
      expect(vm.error, contains('network error'));
      expect(vm.activeSession, isNull);
    });
  });

  // ── logExercise ─────────────────────────────────────────────────────────────

  group('logExercise', () {
    test('appends returned exercise log to activeSession', () async {
      await vm.startSession(date: Fixtures.kDate, dayLabel: 'Day 1 – Push');
      await vm.logExercise(
        exerciseName: 'Bench Press',
        muscleGroup: 'chest',
        sets: const [
          SetEntry(setNumber: 1, reps: 10, weightKg: 60),
          SetEntry(setNumber: 2, reps: 8, weightKg: 65),
        ],
      );

      expect(vm.activeSession!.exerciseLogs.length, 1);
      expect(vm.activeSession!.exerciseLogs.first.exerciseName, 'Bench Press');
      expect(repo.addExerciseLogCalled, true);
      expect(repo.lastAddSessionId, 'sess-001');
    });

    test('order_index matches current log count before call', () async {
      await vm.startSession(date: Fixtures.kDate);
      await vm.logExercise(
        exerciseName: 'Squat',
        sets: const [SetEntry(setNumber: 1, reps: 5, weightKg: 100)],
      );

      expect(repo.lastAddLog!.orderIndex, 0);
    });

    test('does nothing and stays idle when no active session', () async {
      await vm.logExercise(
        exerciseName: 'Squat',
        sets: const [SetEntry(setNumber: 1, reps: 5, weightKg: 100)],
      );

      expect(vm.status, WorkoutLogStatus.idle);
      expect(repo.addExerciseLogCalled, false);
    });

    test('sets status=error when repo throws', () async {
      repo.addExerciseLogError = Exception('server error');
      await vm.startSession(date: Fixtures.kDate);
      await vm.logExercise(
        exerciseName: 'Curl',
        sets: const [SetEntry(setNumber: 1, reps: 12, weightKg: 15)],
      );

      expect(vm.status, WorkoutLogStatus.error);
      expect(vm.activeSession!.exerciseLogs, isEmpty);
    });
  });

  // ── finishSession ───────────────────────────────────────────────────────────

  group('finishSession', () {
    test('marks session completed, sets durationMins, and loads streak',
        () async {
      await vm.startSession(date: Fixtures.kDate, dayLabel: 'Day 1 – Push');
      await vm.finishSession(45);

      expect(vm.status, WorkoutLogStatus.success);
      expect(vm.activeSession!.isCompleted, true);
      expect(vm.activeSession!.durationMins, 45);
      expect(repo.completeSessionCalled, true);
      expect(vm.streak?.currentStreak, 3);
    });

    test('does nothing when no active session', () async {
      await vm.finishSession(30);

      expect(vm.status, WorkoutLogStatus.idle);
      expect(repo.completeSessionCalled, false);
    });
  });

  // ── loadSessions ────────────────────────────────────────────────────────────

  group('loadSessions', () {
    test('populates sessions list on success', () async {
      await vm.loadSessions();

      expect(vm.status, WorkoutLogStatus.success);
      expect(vm.sessions.length, 2);
    });
  });

  // ── loadStreak ───────────────────────────────────────────────────────────────

  group('loadStreak', () {
    test('populates streak and notifies', () async {
      await vm.loadStreak();

      expect(vm.streak?.currentStreak, 3);
      expect(vm.streak?.longestStreak, 7);
    });
  });

  // ── clearActiveSession ──────────────────────────────────────────────────────

  group('clearActiveSession', () {
    test('sets activeSession to null', () async {
      await vm.startSession(date: Fixtures.kDate);
      expect(vm.activeSession, isNotNull);

      vm.clearActiveSession();
      expect(vm.activeSession, isNull);
    });
  });
}
