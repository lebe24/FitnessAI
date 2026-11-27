import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/ui/features/fitness/views/exercise_history_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

final _now = DateTime(2026, 10, 24, 12);

ExerciseHistory _history(List<(int, String)> visits) => ExerciseHistory.fromSessions(
      [
        for (final (day, notes) in visits)
          WorkoutSessionModel(
            sessionDate: DateTime(2026, 10, day),
            workoutLogs: [
              {'name': 'Bench Press', 'sets': 3, 'reps': '8', 'notes': notes},
            ],
          ),
      ],
      'Bench Press',
    );

Widget _host(Future<ExerciseHistory?> history, {VoidCallback? onRetry}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ExerciseHistorySection(
            exerciseName: 'Bench Press',
            history: history,
            onRetry: onRetry ?? () {},
            now: _now,
          ),
        ),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows a spinner while the history loads', (tester) async {
    await tester.pumpWidget(_host(Future<ExerciseHistory?>.delayed(const Duration(seconds: 1), () => null)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('says so when nothing has been logged yet', (tester) async {
    await tester.pumpWidget(_host(Future.value(ExerciseHistory.empty)));
    await tester.pumpAndSettle();
    expect(find.textContaining('No history for this exercise yet'), findsOneWidget);
    expect(find.text('Last time'), findsNothing);
  });

  testWidgets('offers a retry when the sessions could not be read', (tester) async {
    var retried = 0;
    await tester.pumpWidget(_host(Future.value(null), onRetry: () => retried++));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load your history."), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, 1);
  });

  testWidgets('shows last time with each set, the best set and the volume', (tester) async {
    await tester.pumpWidget(_host(Future.value(_history([
      (23, 'set 1: 10 reps @ 60kg | set 2: 8 reps @ 60kg'),
    ]))));
    await tester.pumpAndSettle();

    expect(find.text('Last time'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('10 × 60 kg'), findsWidgets); // a chip, and the best set
    expect(find.text('8 × 60 kg'), findsOneWidget);
    expect(find.text('Best set'), findsOneWidget);
    expect(find.text('1080 kg'), findsOneWidget);
  });

  testWidgets('flags progress against the visit before', (tester) async {
    await tester.pumpWidget(_host(Future.value(_history([
      (23, 'set 1: 5 reps @ 62.5kg'),
      (16, 'set 1: 5 reps @ 60kg'),
    ]))));
    await tester.pumpAndSettle();
    expect(find.text('+2.5 kg'), findsOneWidget);
  });

  testWidgets('lists the earlier visits underneath', (tester) async {
    await tester.pumpWidget(_host(Future.value(_history([
      (23, 'set 1: 5 reps @ 62.5kg'),
      (20, 'set 1: 5 reps @ 60kg'),
      (10, 'set 1: 5 reps @ 57.5kg'),
    ]))));
    await tester.pumpAndSettle();
    expect(find.text('4 days ago'), findsOneWidget);
    expect(find.text('10 Oct'), findsOneWidget);
    expect(find.textContaining('See all'), findsNothing); // everything already shown
  });

  testWidgets('puts the rest behind "See all" once there are more than four', (tester) async {
    await tester.pumpWidget(_host(Future.value(_history([
      for (var d = 1; d <= 7; d++) (d, 'set 1: 5 reps @ ${50 + d}kg'),
    ]))));
    await tester.pumpAndSettle();
    expect(find.text('See all 7 sessions'), findsOneWidget);
  });

  group('historyDayLabel', () {
    test('uses plain words for the last week, then a date', () {
      expect(historyDayLabel(DateTime(2026, 10, 24), _now), 'Today');
      expect(historyDayLabel(DateTime(2026, 10, 23), _now), 'Yesterday');
      expect(historyDayLabel(DateTime(2026, 10, 19), _now), '5 days ago');
      expect(historyDayLabel(DateTime(2026, 10, 10), _now), '10 Oct');
      expect(historyDayLabel(DateTime(2025, 12, 31), _now), '31 Dec 2025');
    });
  });
}
