import 'dart:async';

import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_service.dart';
import 'package:fitness/domain/models/volume_format.dart';
import 'package:fitness/ui/features/analytic/history_samples.dart';
import 'package:fitness/ui/features/analytic/views/session_detail_page.dart';
import 'package:fitness/ui/features/analytic/views/workout_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../fakes/recording_analytics.dart';

Future<void> _pump(
  WidgetTester t,
  Future<List<WorkoutSessionModel>> Function() loader, {
  bool imperial = false,
  double width = 390,
}) async {
  t.view.physicalSize = Size(width, 6000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(home: WorkoutHistoryPage(loader: loader, imperial: imperial)));
  await t.pumpAndSettle();
}

Future<List<WorkoutSessionModel>> _all() async => HistorySamples.all;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows a spinner while loading, then the sessions', (t) async {
    final c = Completer<List<WorkoutSessionModel>>();
    t.view.physicalSize = const Size(390, 6000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: WorkoutHistoryPage(loader: () => c.future, imperial: false)));
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    c.complete(HistorySamples.all);
    await t.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Thu, Nov 20'), findsOneWidget);
  });

  testWidgets('the subtitle is fixed and the title is the design title', (t) async {
    await _pump(t, _all);
    expect(find.text('Workout history'), findsOneWidget);
    expect(find.text('Every session you log'), findsOneWidget);
  });

  testWidgets('has a chip for All and each month with sessions, newest month selected', (t) async {
    // Wide enough for every chip in the test font, so none is scrolled off.
    await _pump(t, _all, width: 900);
    for (final m in ['All', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov']) {
      expect(find.text(m), findsOneWidget, reason: m);
    }
    expect(find.text('Dec'), findsNothing);
    expect(find.bySemanticsLabel('Nov'), findsOneWidget);
    // Opens on November.
    expect(find.text('Thu, Nov 20'), findsOneWidget);
    expect(find.text('Thu, Oct 30'), findsNothing);
  });

  testWidgets('choosing a month filters the list, and All brings everything back', (t) async {
    await _pump(t, _all);

    await t.tap(find.text('Aug'));
    await t.pumpAndSettle();
    expect(find.text('Tue, Aug 19'), findsOneWidget);
    expect(find.text('Tue, Aug 5'), findsOneWidget);
    expect(find.text('Thu, Nov 20'), findsNothing);

    await t.tap(find.text('All'));
    await t.pumpAndSettle();
    expect(find.text('Thu, Nov 20'), findsOneWidget);
    expect(find.text('Tue, Aug 19'), findsOneWidget);
    expect(find.text('Mon, Jul 21'), findsOneWidget);
  });

  testWidgets('cards show duration, exercises and volume as in the design', (t) async {
    await _pump(t, _all);
    expect(find.text('Legs & Core'), findsOneWidget);
    expect(find.text('58 min'), findsOneWidget);
    expect(find.text('7 exercises'), findsOneWidget);
    expect(find.text('9,420 kg'), findsOneWidget);
    expect(find.text('SESSION'), findsNWidgets(4));
  });

  testWidgets('a session with no duration shows no minutes, and no name falls back', (t) async {
    await _pump(t, _all);
    await t.tap(find.text('Sep'));
    await t.pumpAndSettle();

    expect(find.text('Wednesday'), findsOneWidget);
    expect(find.text('Session'), findsOneWidget);
    expect(find.text('0 min'), findsNothing);
    expect(find.text('44 min'), findsOneWidget);
  });

  testWidgets('a session with no measurable load shows no volume', (t) async {
    final bodyweight = WorkoutSessionModel(
      sessionDate: DateTime(2025, 11, 3),
      dayLabel: 'Calisthenics',
      durationMins: 30,
      workoutLogs: const [
        {'name': 'Push-up', 'notes': 'set 1: 15 reps @ 0kg | set 2: 12 reps @ 0kg'},
      ],
    );
    await _pump(t, () async => [bodyweight]);

    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('1 exercise'), findsOneWidget);
    expect(find.textContaining(' kg'), findsNothing);
  });

  testWidgets('shows pounds when the unit is imperial', (t) async {
    await _pump(t, _all, imperial: true);
    expect(find.text(formatVolume(9420, imperial: true)), findsOneWidget);
    expect(find.text('9,420 kg'), findsNothing);
  });

  testWidgets('chips carry the year when the history spans more than one', (t) async {
    await _pump(t, () async => [
          HistorySamples.session(DateTime(2024, 11, 5), 'A', minutes: 40, exercises: 3, totalKg: 3000),
          HistorySamples.session(DateTime(2025, 11, 5), 'B', minutes: 40, exercises: 3, totalKg: 3000),
        ], width: 900);
    expect(find.text("Nov '24"), findsOneWidget);
    expect(find.text("Nov '25"), findsOneWidget);
  });

  testWidgets('empty history says so and has no chips', (t) async {
    await _pump(t, () async => []);
    expect(find.text('No sessions yet'), findsOneWidget);
    expect(find.text('All'), findsNothing);
  });

  testWidgets('a failed load can be retried', (t) async {
    var calls = 0;
    await _pump(t, () async {
      calls++;
      if (calls == 1) throw Exception('offline');
      return HistorySamples.all;
    });
    expect(find.text("Couldn't load your history"), findsOneWidget);
    expect(find.text('All'), findsNothing);

    await t.tap(find.text('Try again'));
    await t.pumpAndSettle();
    expect(find.text('Thu, Nov 20'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('tapping a session opens its detail, and back returns', (t) async {
    await _pump(t, _all);

    await t.tap(find.text('Legs & Core'));
    await t.pumpAndSettle();
    expect(find.byType(SessionDetailPage), findsOneWidget);
    expect(find.text('Barbell Back Squat'), findsOneWidget);

    await t.tap(find.bySemanticsLabel('Back'));
    await t.pumpAndSettle();
    expect(find.byType(SessionDetailPage), findsNothing);
    expect(find.text('Thu, Nov 20'), findsOneWidget);
  });

  testWidgets('the month you chose survives opening and closing a session', (t) async {
    await _pump(t, _all);
    await t.tap(find.text('Oct'));
    await t.pumpAndSettle();

    await t.tap(find.text('Thu, Oct 30'));
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Back'));
    await t.pumpAndSettle();

    expect(find.text('Thu, Oct 30'), findsOneWidget);
    expect(find.text('Thu, Nov 20'), findsNothing);
  });

  testWidgets('does not overflow on a narrow phone, in pounds with big numbers', (t) async {
    await _pump(t, () async => [
          HistorySamples.session(DateTime(2025, 11, 20), 'A very long workout name that keeps going and going',
              minutes: 125, exercises: 7, totalKg: 123450),
        ], width: 320, imperial: true);
    expect(t.takeException(), isNull);
    expect(find.text('125 min'), findsOneWidget);
    expect(find.text('7 exercises'), findsOneWidget);
  });

  group('analytics', () {
    late RecordingAnalytics rec;
    setUp(() {
      rec = RecordingAnalytics();
      Analytics.use(rec);
    });
    tearDown(() => Analytics.use(NoopAnalyticsService()));

    List<Map<String, Object?>?> named(String n) => [for (final e in rec.events) if (e.$1 == n) e.$2];

    testWidgets('opening the history reports the screen, how many sessions and months', (t) async {
      await _pump(t, _all);
      expect(rec.screens, contains('workout_history'));
      expect(named('workout_history_opened'), [
        {'sessions': 12, 'months': 5}
      ]);
    });

    testWidgets('pulling to refresh does not count as opening it again', (t) async {
      await _pump(t, _all);
      await t.fling(find.byType(ListView).last, const Offset(0, 300), 1000);
      await t.pumpAndSettle();
      expect(named('workout_history_opened'), hasLength(1));
    });

    testWidgets('choosing a month, and All, is reported without saying which month', (t) async {
      await _pump(t, _all);
      await t.tap(find.text('Aug'));
      await t.pumpAndSettle();
      await t.tap(find.text('All'));
      await t.pumpAndSettle();

      expect(named('workout_history_month_selected'), [
        {'all': false},
        {'all': true},
      ]);
    });

    testWidgets('opening a session reports its size, not its name or numbers', (t) async {
      await _pump(t, _all);
      await t.tap(find.text('Legs & Core'));
      await t.pumpAndSettle();

      expect(named('workout_session_opened'), [
        {'exercises': 7, 'has_feedback': true}
      ]);
      expect(rec.screens, contains('workout_session'));

      final all = rec.events.map((e) => '${e.$1} ${e.$2}').join('\n');
      for (final secret in ['Legs', 'Squat', '9,420', '9420', '58']) {
        expect(all.contains(secret), isFalse, reason: secret);
      }
    });
  });
}
