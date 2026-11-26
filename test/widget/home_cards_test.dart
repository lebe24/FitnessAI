import 'package:fitness/domain/models/workout_day_mapping.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/ui/features/fitness/views/saved_workouts_card.dart';
import 'package:fitness/ui/features/muscle_map/views/muscle_map_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

// Wednesday 25 Nov 2026, so the week is Mon 23 to Sun 29.
final _now = DateTime(2026, 11, 25, 9);

WorkoutDayMappingEntity _session(int day, String focus, {int exercises = 5, int month = 11}) =>
    WorkoutDayMappingEntity(
      date: DateTime(2026, month, day),
      workoutDay: WorkoutDay(
        day: 'Day',
        focus: focus,
        exercises: [
          for (var i = 0; i < exercises; i++)
            Exercise(name: 'Exercise $i', sets: 3, reps: '10'),
        ],
      ),
    );

Map<DateTime, WorkoutDayMappingEntity> _byDate(List<WorkoutDayMappingEntity> l) =>
    {for (final m in l) DateTime(m.date.year, m.date.month, m.date.day): m};

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0C12),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('which sessions the program card lists', () {
    test('lists the sessions of the current week, in date order', () {
      final got = SavedWorkoutsCard.sessionsFor(
        _byDate([_session(27, 'Legs'), _session(23, 'Chest'), _session(25, 'Back')]),
        _now,
      );
      expect(got.map((m) => m.workoutDay!.focus), ['Chest', 'Back', 'Legs']);
    });

    test('leaves out sessions from other weeks', () {
      final got = SavedWorkoutsCard.sessionsFor(
        _byDate([_session(20, 'Last week'), _session(25, 'This week'), _session(30, 'Next week')]),
        _now,
      );
      expect(got.map((m) => m.workoutDay!.focus), ['This week']);
    });

    test('keeps the next session in view when the week has more than four', () {
      final week = [
        _session(23, 'Mon'), _session(24, 'Tue'), _session(25, 'Wed'),
        _session(26, 'Thu'), _session(27, 'Fri'), _session(28, 'Sat'),
      ];
      final got = SavedWorkoutsCard.sessionsFor(_byDate(week), _now);
      // Today is Wednesday: two sessions of context, today, then what is next.
      expect(got.map((m) => m.workoutDay!.focus), ['Mon', 'Tue', 'Wed', 'Thu']);
      final late = SavedWorkoutsCard.sessionsFor(_byDate(week), DateTime(2026, 11, 28));
      expect(late.map((m) => m.workoutDay!.focus), ['Wed', 'Thu', 'Fri', 'Sat']);
    });

    test('looks ahead when nothing is planned this week', () {
      final got = SavedWorkoutsCard.sessionsFor(
        _byDate([_session(20, 'Past'), _session(30, 'Soon'), _session(2, 'Soon too', month: 12)]),
        _now,
      );
      expect(got.map((m) => m.workoutDay!.focus), ['Soon', 'Soon too']);
    });

    test('lists nothing when there are no sessions', () {
      expect(SavedWorkoutsCard.sessionsFor({}, _now), isEmpty);
    });
  });

  group('workout program card', () {
    testWidgets('shows each session with its state', (tester) async {
      var taps = 0;
      final today = DateTime.now();
      final todayDay = DateTime(today.year, today.month, today.day);
      WorkoutDayMappingEntity on(DateTime d, String focus, int n) => WorkoutDayMappingEntity(
            date: d,
            workoutDay: WorkoutDay(
              day: 'Day',
              focus: focus,
              exercises: [for (var i = 0; i < n; i++) Exercise(name: 'E$i', sets: 3, reps: '10')],
            ),
          );

      await tester.pumpWidget(_host(WorkoutProgramCardView(
        sessions: [
          on(todayDay.subtract(const Duration(days: 1)), 'Back & Biceps', 6),
          on(todayDay, 'Legs & Core', 7),
          on(todayDay.add(const Duration(days: 1)), 'Shoulders & Arms', 1),
        ],
        completedDates: {todayDay.subtract(const Duration(days: 1))},
        viewAllLabel: 'View all',
        onTap: () => taps++,
      )));
      await tester.pumpAndSettle();

      expect(find.text('My Workout Program'), findsOneWidget);
      expect(find.text('View all'), findsOneWidget);
      expect(find.text('Back & Biceps'), findsOneWidget);
      expect(find.text('Legs & Core'), findsOneWidget);
      // done, today, and upcoming each read differently
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(find.text('Training'), findsOneWidget);
      expect(find.text('1 exercise'), findsOneWidget);

      await tester.tap(find.text('My Workout Program'));
      expect(taps, 1);
    });

    testWidgets('says so when nothing is scheduled', (tester) async {
      await tester.pumpWidget(_host(WorkoutProgramCardView(
        sessions: const [],
        completedDates: const {},
        viewAllLabel: 'View all',
        onTap: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('No workouts scheduled'), findsOneWidget);
    });
  });

  group('muscle map card', () {
    testWidgets('names the map, offers it, and reports a tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(MuscleMapCardView(locked: false, onTap: () => taps++)));
      await tester.pumpAndSettle();

      expect(find.text('Muscle Map'), findsOneWidget);
      expect(find.text('Open map'), findsOneWidget);
      expect(find.text('PRO'), findsNothing);

      await tester.tap(find.text('Open map'));
      expect(taps, 1);
    });

    testWidgets('marks the card Pro while it is locked', (tester) async {
      await tester.pumpWidget(_host(MuscleMapCardView(locked: true, onTap: () {})));
      await tester.pumpAndSettle();
      expect(find.text('PRO'), findsOneWidget);
    });
  });
}
