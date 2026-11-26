import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/ui/features/analytic/history_samples.dart';
import 'package:fitness/ui/features/analytic/views/session_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _pump(WidgetTester t, WorkoutSessionModel s, {bool imperial = false}) async {
  t.view.physicalSize = const Size(390, 5000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(home: SessionDetailPage(session: s, imperial: imperial)));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows the title, the date and the three numbers', (t) async {
    await _pump(t, HistorySamples.all.first);
    expect(find.text('Legs & Core'), findsOneWidget);
    expect(find.text('Thursday, November 20'), findsOneWidget);
    expect(find.text('58 min'), findsOneWidget);
    expect(find.text('9,420 kg'), findsOneWidget);
    expect(find.text('Exercises'), findsOneWidget);
  });

  testWidgets('lists each exercise once, with its sets', (t) async {
    await _pump(t, HistorySamples.all.first);
    // The stored blob also holds a coaching entry per exercise; only the
    // performed one is listed.
    expect(find.text('Barbell Back Squat'), findsOneWidget);
    expect(find.text('Romanian Deadlift'), findsOneWidget);
    expect(find.text('10 × 45 kg'), findsWidgets);
    expect(find.textContaining('3 sets'), findsWidgets);
  });

  testWidgets('shows a skipped set dimmed instead of hiding it', (t) async {
    final s = WorkoutSessionModel(
      sessionDate: DateTime(2025, 11, 3),
      workoutLogs: const [
        {'name': 'Bench Press', 'notes': 'set 1: 8 reps @ 60kg | set 2: 0 reps @ 60kg'},
      ],
    );
    await _pump(t, s);
    expect(find.text('8 × 60 kg'), findsOneWidget);
    expect(find.text('skipped'), findsOneWidget);
    expect(find.textContaining('1 set'), findsWidgets);
  });

  testWidgets('shows set weights in pounds when imperial', (t) async {
    final s = WorkoutSessionModel(
      sessionDate: DateTime(2025, 11, 3),
      workoutLogs: const [
        {'name': 'Bench Press', 'notes': 'set 1: 8 reps @ 60kg'},
      ],
    );
    await _pump(t, s, imperial: true);
    expect(find.text('8 × 132.3 lb'), findsOneWidget);
    expect(find.textContaining('kg'), findsNothing);
  });

  testWidgets('shows the coach feedback when one was saved', (t) async {
    await _pump(t, HistorySamples.all.first);
    expect(find.text('Coach feedback'), findsOneWidget);
    expect(find.text('WENT WELL'), findsOneWidget);
    expect(find.text('TO IMPROVE'), findsOneWidget);
    expect(find.text('NEXT SESSION'), findsOneWidget);
    expect(find.textContaining('35 g of protein'), findsOneWidget);
  });

  testWidgets('shows no feedback section when none was saved', (t) async {
    await _pump(t, HistorySamples.all[1]);
    expect(find.text('Coach feedback'), findsNothing);
  });

  testWidgets('skips the parts of feedback that are missing', (t) async {
    final s = WorkoutSessionModel(
      sessionDate: DateTime(2025, 11, 3),
      workoutLogs: const [
        {'name': 'Bench Press', 'notes': 'set 1: 8 reps @ 60kg'},
      ],
      feedback: const {'next_session_tip': 'Add a set.', 'performance_highlights': []},
    );
    await _pump(t, s);
    expect(find.text('Coach feedback'), findsOneWidget);
    expect(find.text('NEXT SESSION'), findsOneWidget);
    expect(find.text('WENT WELL'), findsNothing);
    expect(find.text('AFTER THE SESSION'), findsNothing);
  });

  testWidgets('a session with no sets says so', (t) async {
    final s = WorkoutSessionModel(sessionDate: DateTime(2025, 11, 3), dayLabel: 'Monday');
    await _pump(t, s);
    expect(find.text('No sets were saved for this session.'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('not recorded'), findsOneWidget);
  });

  testWidgets('a bodyweight-only session shows no volume figure', (t) async {
    final s = WorkoutSessionModel(
      sessionDate: DateTime(2025, 11, 3),
      workoutLogs: const [
        {'name': 'Push-up', 'notes': 'set 1: 15 reps @ 0kg'},
      ],
    );
    await _pump(t, s);
    expect(find.text('bodyweight only'), findsOneWidget);
    expect(find.text('15 reps'), findsOneWidget);
  });

  testWidgets('the back button leaves the page', (t) async {
    t.view.physicalSize = const Size(390, 5000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => SessionDetailPage(session: HistorySamples.all.first, imperial: false))),
          child: const Text('open'),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.byType(SessionDetailPage), findsOneWidget);

    await t.tap(find.bySemanticsLabel('Back'));
    await t.pumpAndSettle();
    expect(find.byType(SessionDetailPage), findsNothing);
  });
}
