import 'package:fitness/data/models/onboarding/onboarding_data.dart';
import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_service.dart';
import 'package:fitness/ui/features/profile/views/adjust_workout_plan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../fakes/recording_analytics.dart';

const _saved = OnboardingData(
  goal: 'Build Muscle',
  experience: 'Experienced',
  workoutDays: 4,
  gender: 'Male',
  height: '178 cm',
  weight: '78 kg',
);

class _Run {
  final saved = <OnboardingData>[];
  int continued = 0;
}

Future<_Run> _pump(WidgetTester t, {OnboardingData? data = _saved, double width = 390}) async {
  final run = _Run();
  t.view.physicalSize = Size(width, 1800);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    home: AdjustWorkoutPlanPage(
      load: () async => data,
      save: (d) async => run.saved.add(d),
      onContinue: () => run.continued++,
    ),
  ));
  await t.pumpAndSettle();
  return run;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows the design: title, sections and button', (t) async {
    await _pump(t);
    expect(find.text('Adjust Workout Plan'), findsOneWidget);
    for (final s in ['Goal', 'Experience Level', 'Training Days / Week', 'Gender', 'Height', 'Weight']) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(find.text('Continue to Photo Scan'), findsOneWidget);
  });

  testWidgets('the goal emoji are unchanged', (t) async {
    await _pump(t);
    for (final e in ['🔥', '💪', '⚖️', '🎨']) {
      expect(find.text(e), findsOneWidget, reason: e);
      expect(t.widget<Text>(find.text(e)).style!.fontSize, 20);
    }
    for (final g in ['Lose Weight', 'Build Muscle', 'Maintain Gains', 'Build Aesthetics']) {
      expect(find.text(g), findsOneWidget, reason: g);
    }
  });

  testWidgets('keeps all four experience levels and adds Other to gender', (t) async {
    await _pump(t);
    for (final e in ['Beginner', 'Experienced', 'Freak of Nature', 'God in Human Form']) {
      expect(find.text(e), findsOneWidget, reason: e);
    }
    for (final g in ['Female', 'Male', 'Other']) {
      expect(find.text(g), findsOneWidget, reason: g);
    }
  });

  testWidgets('saves what was chosen, and continues', (t) async {
    final run = await _pump(t);

    await t.tap(find.text('Lose Weight'));
    await t.tap(find.text('God in Human Form'));
    await t.tap(find.text('6'));
    await t.tap(find.text('Other'));
    await t.pumpAndSettle();

    await t.tap(find.text('Continue to Photo Scan'));
    await t.pumpAndSettle();

    expect(run.saved, hasLength(1));
    final d = run.saved.single;
    expect(d.goal, 'Lose Weight');
    expect(d.experience, 'God in Human Form');
    expect(d.workoutDays, 6);
    expect(d.gender, 'Other');
    expect(d.height, '178 cm');
    expect(d.weight, '78 kg');
    expect(run.continued, 1);
  });

  testWidgets('keeps the saved answers when nothing is changed', (t) async {
    final run = await _pump(t);
    await t.tap(find.text('Continue to Photo Scan'));
    await t.pumpAndSettle();

    final d = run.saved.single;
    expect(d.goal, 'Build Muscle');
    expect(d.experience, 'Experienced');
    expect(d.workoutDays, 4);
    expect(d.gender, 'Male');
  });

  testWidgets('will not continue until gender, goal and experience are chosen', (t) async {
    final run = await _pump(t, data: null);

    await t.tap(find.text('Continue to Photo Scan'));
    await t.pump();
    expect(find.text('Please fill in gender, goal and experience before continuing.'), findsOneWidget);
    expect(run.saved, isEmpty);
    expect(run.continued, 0);

    // The message sits over the button until it is dismissed.
    ScaffoldMessenger.of(t.element(find.byType(Scaffold))).hideCurrentSnackBar();
    await t.pumpAndSettle();
    await t.tap(find.text('Build Aesthetics'));
    await t.tap(find.text('Beginner'));
    await t.tap(find.text('Female'));
    await t.pumpAndSettle();
    await t.tap(find.text('Continue to Photo Scan'));
    await t.pumpAndSettle();
    expect(run.saved, hasLength(1));
    expect(run.saved.single.workoutDays, 3); // the default
  });

  testWidgets('flipping a unit converts the number instead of relabelling it', (t) async {
    final run = await _pump(t);
    expect(find.text('cm'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);

    await t.tap(find.text('cm'));
    await t.tap(find.text('kg'));
    await t.pumpAndSettle();
    expect(find.text('ft'), findsWidgets);
    expect(find.text('lbs'), findsOneWidget);

    final texts = t.widgetList<TextField>(find.byType(TextField)).map((f) => f.controller!.text).toList();
    expect(texts, ['5', '10', '172']); // 178 cm is 5 ft 10 in, 78 kg is 172 lbs

    await t.tap(find.text('Continue to Photo Scan'));
    await t.pumpAndSettle();
    expect(run.saved.single.height, '5 ft 10 in');
    expect(run.saved.single.weight, '172 lbs');
  });

  testWidgets('flipping back and forth keeps the same person', (t) async {
    final run = await _pump(t);
    await t.tap(find.text('cm'));
    await t.pumpAndSettle();
    await t.tap(find.text('ft').last);
    await t.pumpAndSettle();

    await t.tap(find.text('Continue to Photo Scan'));
    await t.pumpAndSettle();
    expect(run.saved.single.height, '178 cm');
  });

  group('height written by other screens', () {
    Future<List<String>> fields(WidgetTester t) async =>
        t.widgetList<TextField>(find.byType(TextField)).map((f) => f.controller!.text).toList();

    testWidgets('onboarding feet and inches load as feet and inches, not just "5"', (t) async {
      final run = await _pump(t, data: _saved.copyWith(height: '5 ft 10 in'));
      expect((await fields(t)).take(2), ['5', '10']);

      await t.tap(find.text('Continue to Photo Scan'));
      await t.pumpAndSettle();
      expect(run.saved.single.height, '5 ft 10 in');
    });

    testWidgets('onboarding metres load as centimetres, not "1.8 cm"', (t) async {
      final run = await _pump(t, data: _saved.copyWith(height: '1.8 m'));
      expect((await fields(t)).first, '180');

      await t.tap(find.text('Continue to Photo Scan'));
      await t.pumpAndSettle();
      expect(run.saved.single.height, '180 cm');
    });

    testWidgets('the old decimal feet become feet and inches', (t) async {
      final run = await _pump(t, data: _saved.copyWith(height: '5.9 ft'));
      expect((await fields(t)).take(2), ['5', '11']);

      await t.tap(find.text('Continue to Photo Scan'));
      await t.pumpAndSettle();
      expect(run.saved.single.height, '5 ft 11 in');
    });

    testWidgets('a height that is not a height is not saved', (t) async {
      final run = await _pump(t);
      await t.enterText(find.byType(TextField).first, '17');
      await t.tap(find.text('Continue to Photo Scan'));
      await t.pumpAndSettle();

      expect(find.text('Enter your height in centimetres, like 178.'), findsOneWidget);
      expect(run.saved, isEmpty);
    });

    testWidgets('feet and inches are checked too', (t) async {
      final run = await _pump(t, data: _saved.copyWith(height: '5 ft 10 in'));
      await t.enterText(find.byType(TextField).at(1), '14');
      await t.tap(find.text('Continue to Photo Scan'));
      await t.pumpAndSettle();

      expect(find.text('Enter your height as feet and inches, like 5 and 10.'), findsOneWidget);
      expect(run.saved, isEmpty);
    });

    testWidgets('leaving height empty keeps what was stored', (t) async {
      final run = await _pump(t, data: _saved.copyWith(height: '5 ft 10 in'));
      await t.enterText(find.byType(TextField).first, '');
      await t.tap(find.text('Continue to Photo Scan'));
      await t.pumpAndSettle();
      expect(run.saved.single.height, '5 ft 10 in');
    });
  });

  testWidgets('typed height and weight are white, not black', (t) async {
    await _pump(t);
    final fields = t.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields, hasLength(2));
    for (final f in fields) {
      expect(f.style!.color, Colors.white);
    }
    expect(fields.map((f) => f.controller!.text), ['178', '78']);
  });

  testWidgets('shows a spinner until the saved answers arrive', (t) async {
    await t.pumpWidget(MaterialApp(
      home: AdjustWorkoutPlanPage(
        load: () => Future.delayed(const Duration(seconds: 1), () => _saved),
        save: (_) async {},
        onContinue: () {},
      ),
    ));
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await t.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('does not overflow on a narrow phone', (t) async {
    await _pump(t, width: 320);
    expect(t.takeException(), isNull);
  });

  testWidgets('the back button leaves the page', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => AdjustWorkoutPlanPage(load: () async => _saved, save: (_) async {}, onContinue: () {}))),
          child: const Text('open'),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.byType(AdjustWorkoutPlanPage), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Back'));
    await t.pumpAndSettle();
    expect(find.byType(AdjustWorkoutPlanPage), findsNothing);
  });

  testWidgets('chips hug their text instead of stretching across the screen', (t) async {
    await _pump(t);
    for (final label in ['Beginner', 'Female', 'Other']) {
      final chip = find.ancestor(of: find.text(label), matching: find.byType(AnimatedContainer)).first;
      expect(t.getSize(chip).width, lessThan(200), reason: label);
    }
    // And two fit side by side.
    final female = t.getRect(find.ancestor(of: find.text('Female'), matching: find.byType(AnimatedContainer)).first);
    final male = t.getRect(find.ancestor(of: find.text('Male'), matching: find.byType(AnimatedContainer)).first);
    expect(female.top, male.top);
  });

  group('analytics', () {
    late RecordingAnalytics rec;
    setUp(() {
      rec = RecordingAnalytics();
      Analytics.use(rec);
    });
    tearDown(() => Analytics.use(NoopAnalyticsService()));

    List<Map<String, Object?>?> named(String n) => [for (final e in rec.events) if (e.$1 == n) e.$2];

    testWidgets('reports the screen', (t) async {
      await _pump(t);
      expect(rec.screens, contains('adjust_plan'));
    });

    testWidgets('submitting says what the plan is now and what was changed', (t) async {
      await _pump(t);
      await t.tap(find.text('Lose Weight'));
      await t.tap(find.text('6'));
      await t.pumpAndSettle();
      await t.tap(find.text('Continue to Photo Scan'));
      await t.pumpAndSettle();

      expect(named('plan_adjust_submitted'), [
        {
          'goal': 'Lose Weight',
          'experience': 'Experienced',
          'days_per_week': 6,
          'changed_goal': true,
          'changed_experience': false,
          'changed_days': true,
          'height_unit': 'metric',
          'weight_unit': 'metric',
        }
      ]);
    });

    testWidgets('units are reported as the person left them', (t) async {
      await _pump(t, data: _saved.copyWith(height: '5 ft 10 in', weight: '172 lbs'));
      await t.tap(find.text('Continue to Photo Scan'));
      await t.pumpAndSettle();
      final e = named('plan_adjust_submitted').single!;
      expect(e['height_unit'], 'imperial');
      expect(e['weight_unit'], 'imperial');
    });

    testWidgets('a blocked attempt says why, and is not a submission', (t) async {
      await _pump(t, data: null);
      await t.tap(find.text('Continue to Photo Scan'));
      await t.pump();
      expect(named('plan_adjust_blocked'), [
        {'reason': 'missing_fields'}
      ]);
      expect(named('plan_adjust_submitted'), isEmpty);
    });

    testWidgets('a bad height is reported as such', (t) async {
      await _pump(t);
      await t.enterText(find.byType(TextField).first, '17');
      await t.tap(find.text('Continue to Photo Scan'));
      await t.pump();
      expect(named('plan_adjust_blocked'), [
        {'reason': 'invalid_height'}
      ]);
    });

    testWidgets('a goal someone typed is "custom", and body details are never sent', (t) async {
      await _pump(t, data: _saved.copyWith(goal: 'Look good at my wedding in June, I am Sam'));
      await t.tap(find.text('Continue to Photo Scan'));
      await t.pumpAndSettle();

      final e = named('plan_adjust_submitted').single!;
      expect(e['goal'], 'custom');

      final all = rec.events.map((e) => '${e.$1} ${e.$2}').join('\n');
      for (final secret in ['wedding', 'Sam', '178', '78', 'Male', 'Female']) {
        expect(all.contains(secret), isFalse, reason: secret);
      }
    });
  });
}
