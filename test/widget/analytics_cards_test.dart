import 'package:fitness/domain/body/body_advice.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/goal_progress.dart';
import 'package:fitness/domain/body/muscle_focus.dart';
import 'package:fitness/ui/features/analytic/analytics_samples.dart';
import 'package:fitness/ui/features/analytic/views/body/advice_card.dart';
import 'package:fitness/ui/features/analytic/views/body/goal_card.dart';
import 'package:fitness/ui/features/analytic/views/body/goal_setup_page.dart';
import 'package:fitness/ui/features/analytic/views/body/log_sheets.dart';
import 'package:fitness/ui/features/analytic/views/body/measurements_card.dart';
import 'package:fitness/ui/features/analytic/views/body/muscle_development_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

final _now = AnalyticsSamples.now;

Future<void> _pump(WidgetTester t, Widget child) async {
  t.view.physicalSize = const Size(400, 2600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
  ));
  await t.pumpAndSettle();
}

/// A full page, such as the goal setup, which brings its own Scaffold and scrolling.
Future<void> _pumpPage(WidgetTester t, Widget page) async {
  t.view.physicalSize = const Size(400, 3000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(home: page));
  await t.pumpAndSettle();
}

MuscleStatus _status(MuscleGroup g, {MuscleLevel level = MuscleLevel.focus, int score = 4, bool pinned = false}) =>
    MuscleStatus(
      group: g, level: level, score: score, weeklySets: 5, targetSets: 9, strengthTrendPct: -3.4,
      daysSinceTrained: 6, pinned: pinned, reason: '5 sets a week against about 9.',
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('goal card', () {
    testWidgets('invites you to set a goal when there is none', (t) async {
      var set = 0;
      await _pump(t, GoalCard(
        progress: GoalProgress.of(null, const [], _now),
        imperial: false, now: _now, onSetGoal: () => set++, onLogWeight: () {},
      ));
      expect(find.text('Set your goal'), findsOneWidget);
      await t.tap(find.text('Set a goal'));
      expect(set, 1);
    });

    testWidgets('shows where you are, how it is going and what to eat', (t) async {
      var logged = 0;
      await _pump(t, GoalCard(
        progress: AnalyticsSamples.progress,
        imperial: false, now: _now, onSetGoal: () {}, onLogWeight: () => logged++,
      ));
      expect(find.text('Lose weight'), findsOneWidget);
      expect(find.text('On track'), findsOneWidget);
      expect(find.text('80.2 kg'), findsOneWidget);
      expect(find.textContaining('76 kg'), findsOneWidget);
      expect(find.textContaining('550 kcal a day below maintenance'), findsOneWidget);
      await t.tap(find.text('Log weight'));
      expect(logged, 1);
    });

    testWidgets('speaks in pounds when asked', (t) async {
      await _pump(t, GoalCard(
        progress: AnalyticsSamples.progress,
        imperial: true, now: _now, onSetGoal: () {}, onLogWeight: () {},
      ));
      expect(find.text('176.8 lb'), findsOneWidget);
    });

    testWidgets('warns when the change is too fast', (t) async {
      final fast = GoalProgress.of(
        const FitnessGoal(type: GoalType.loseWeight, startWeightKg: 90, targetWeightKg: 75, weeklyRateKg: 0.4),
        [
          for (final (d, kg) in <(int, double)>[(21, 90), (14, 87.5), (7, 85), (0, 82.5)])
            BodyWeightEntry(date: DateTime(2026, 11, 25).subtract(Duration(days: d)), weightKg: kg)
        ],
        _now,
      );
      await _pump(t, GoalCard(progress: fast, imperial: false, now: _now, onSetGoal: () {}, onLogWeight: () {}));
      expect(find.text('Too fast'), findsOneWidget);
      expect(find.textContaining('faster than is wise'), findsOneWidget);
    });
  });

  group('log weight sheet', () {
    Future<List<Object?>> open(WidgetTester t, {bool imperial = false, double? last = 80}) async {
      final saved = <Object?>[];
      await _pump(t, LogWeightSheet(
        lastKg: last, imperial: imperial, onUnitChanged: (_) {},
        onSave: (kg, d, n) async {
          saved.add(kg);
          return true;
        },
      ));
      return saved;
    }

    testWidgets('rejects text that is not a number', (t) async {
      final saved = await open(t);
      await t.enterText(find.byType(TextField).first, 'abc');
      await t.tap(find.text('Save'));
      await t.pump();
      expect(find.text('Enter your weight as a number.'), findsOneWidget);
      expect(saved, isEmpty);
    });

    testWidgets('rejects a weight no one has', (t) async {
      final saved = await open(t);
      await t.enterText(find.byType(TextField).first, '12');
      await t.tap(find.text('Save'));
      await t.pump();
      expect(find.textContaining('does not look like a body weight'), findsOneWidget);
      expect(saved, isEmpty);
    });

    testWidgets('saves a good weight in kilograms', (t) async {
      final saved = await open(t);
      await t.enterText(find.byType(TextField).first, '79,4');
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(saved, [79.4]);
    });

    testWidgets('converts pounds to kilograms', (t) async {
      final saved = await open(t, imperial: true);
      await t.enterText(find.byType(TextField).first, '176.4');
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect((saved.single as double), closeTo(80.0, 0.05));
    });

    testWidgets('a big jump needs a second tap to confirm', (t) async {
      final saved = await open(t, last: 80);
      await t.enterText(find.byType(TextField).first, '99');
      await t.tap(find.text('Save'));
      await t.pump();
      expect(find.textContaining('Tap Save again'), findsOneWidget);
      expect(saved, isEmpty);

      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(saved, [99.0]);
    });
  });

  group('log measurements sheet', () {
    testWidgets('needs at least one reading', (t) async {
      await _pump(t, LogMeasurementsSheet(
        latestCm: const {}, imperial: false, onUnitChanged: (_) {}, onSave: (c, d) async => c.length));
      await t.tap(find.text('Save'));
      await t.pump();
      expect(find.text('Enter at least one measurement.'), findsOneWidget);
    });

    testWidgets('saves only what was filled in, converting inches', (t) async {
      Map<MeasurementSite, double>? got;
      await _pump(t, LogMeasurementsSheet(
        latestCm: const {}, imperial: true, onUnitChanged: (_) {},
        onSave: (c, d) async {
          got = c;
          return c.length;
        },
      ));
      await t.enterText(find.byType(TextField).first, '40'); // chest, in inches
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(got!.keys, [MeasurementSite.chest]);
      expect(got![MeasurementSite.chest], closeTo(101.6, 0.01));
    });

    testWidgets('flags a reading that is not possible', (t) async {
      await _pump(t, LogMeasurementsSheet(
        latestCm: const {}, imperial: false, onUnitChanged: (_) {}, onSave: (c, d) async => c.length));
      await t.enterText(find.byType(TextField).first, '900');
      await t.tap(find.text('Save'));
      await t.pump();
      expect(find.text('Check this'), findsOneWidget);
    });
  });

  group('muscle sheet', () {
    testWidgets('pins a muscle as a focus area', (t) async {
      final calls = <bool>[];
      await _pump(t, MuscleFocusSheet(
        status: _status(MuscleGroup.quads), hasGoal: true,
        onSetFocus: (f) async {
          calls.add(f);
          return true;
        },
        onSetGoal: () {},
      ));
      expect(find.text('Quads'), findsOneWidget);
      expect(find.textContaining('Strength down 3.4%'), findsOneWidget);
      await t.tap(find.text('Set as focus area'));
      await t.pumpAndSettle();
      expect(calls, [true]);
      expect(find.text('Remove focus area'), findsOneWidget);
    });

    testWidgets('unpins one that was pinned', (t) async {
      final calls = <bool>[];
      await _pump(t, MuscleFocusSheet(
        status: _status(MuscleGroup.quads, pinned: true), hasGoal: true,
        onSetFocus: (f) async {
          calls.add(f);
          return true;
        },
        onSetGoal: () {},
      ));
      await t.tap(find.text('Remove focus area'));
      await t.pumpAndSettle();
      expect(calls, [false]);
    });

    testWidgets('without a goal it sends you to set one', (t) async {
      var setGoal = 0;
      await _pump(t, Builder(builder: (context) => MuscleFocusSheet(
        status: _status(MuscleGroup.chest), hasGoal: false,
        onSetFocus: (_) async => true, onSetGoal: () => setGoal++,
      )));
      await t.tap(find.text('Set a goal to pin this'));
      await t.pumpAndSettle();
      expect(setGoal, 1);
    });

    testWidgets('says so when pinning fails', (t) async {
      await _pump(t, MuscleFocusSheet(
        status: _status(MuscleGroup.quads), hasGoal: true,
        onSetFocus: (_) async => false, onSetGoal: () {},
      ));
      await t.tap(find.text('Set as focus area'));
      await t.pumpAndSettle();
      expect(find.textContaining('up to six'), findsOneWidget);
    });
  });

  group('suggestions', () {
    test('say how many sets to add', () {
      expect(muscleSuggestion(_status(MuscleGroup.quads)), 'Add 4 sets a week to reach about 9.');
    });

    test('start from nothing', () {
      final none = MuscleStatus(
        group: MuscleGroup.calves, level: MuscleLevel.untrained, score: 1, weeklySets: 0, targetSets: 6.3,
        strengthTrendPct: null, daysSinceTrained: null, pinned: false, reason: '');
      expect(muscleSuggestion(none), 'Add about 7 sets a week to get it going.');
    });
  });

  group('strengths and focus', () {
    testWidgets('lists both and opens a muscle', (t) async {
      MuscleStatus? opened;
      await _pump(t, StrengthsFocusCard(
        strengths: [_status(MuscleGroup.back, level: MuscleLevel.strong, score: 9)],
        focusAreas: [_status(MuscleGroup.quads)],
        onSelect: (m) => opened = m,
      ));
      expect(find.text('FOCUS AREAS'), findsOneWidget);
      expect(find.text('STRENGTHS'), findsOneWidget);
      await t.tap(find.text('Quads'));
      expect(opened!.group, MuscleGroup.quads);
    });

    testWidgets('is absent with nothing to say', (t) async {
      await _pump(t, StrengthsFocusCard(strengths: const [], focusAreas: const [], onSelect: (_) {}));
      expect(find.text('Strengths & Focus Areas'), findsNothing);
    });
  });

  group('advice card', () {
    testWidgets('asks for a goal first', (t) async {
      var set = 0;
      await _pump(t, AdviceCard(
        advice: null, hasGoal: false, loading: false, error: null, onRefresh: () {}, onSetGoal: () => set++));
      await t.tap(find.text('Set a goal'));
      expect(set, 1);
    });

    testWidgets('shows the advice, its actions and the disclaimer', (t) async {
      await _pump(t, AdviceCard(
        advice: AnalyticsSamples.advice, hasGoal: true, loading: false, error: null,
        onRefresh: () {}, onSetGoal: () {}));
      expect(find.text('You are on track to reach 76 kg'), findsOneWidget);
      expect(find.text('Add leg volume'), findsOneWidget);
      expect(find.textContaining('not medical advice'), findsOneWidget);
    });

    testWidgets('says why it could not answer, and offers to retry', (t) async {
      var tries = 0;
      await _pump(t, AdviceCard(
        advice: null, hasGoal: true, loading: false, error: BodyTrackingError.offline,
        onRefresh: () => tries++, onSetGoal: () {}));
      expect(find.textContaining('offline'), findsOneWidget);
      await t.tap(find.text('Try again'));
      expect(tries, 1);
    });

    testWidgets('keeps older advice on screen when a refresh fails', (t) async {
      await _pump(t, AdviceCard(
        advice: AnalyticsSamples.advice, hasGoal: true, loading: false, error: BodyTrackingError.rateLimited,
        onRefresh: () {}, onSetGoal: () {}));
      expect(find.text('You are on track to reach 76 kg'), findsOneWidget);
      expect(find.textContaining('Try again in a minute'), findsOneWidget);
    });
  });

  group('measurements card', () {
    testWidgets('shows readings and the change since the first', (t) async {
      MeasurementSite? tapped;
      await _pump(t, MeasurementsCard(
        summary: AnalyticsSamples.measurements, imperial: false, goalType: GoalType.loseWeight,
        onUnitChanged: (_) {}, onLog: () {}, onTapSite: (s) => tapped = s));
      expect(find.text('84 cm'), findsOneWidget);
      expect(find.text('3.5 cm'), findsOneWidget);
      expect(find.text('First reading'), findsOneWidget);
      await t.tap(find.text('Waist'));
      expect(tapped, MeasurementSite.waist);
    });

    testWidgets('explains itself when empty', (t) async {
      await _pump(t, MeasurementsCard(
        summary: const {}, imperial: false, goalType: null,
        onUnitChanged: (_) {}, onLog: () {}, onTapSite: (_) {}));
      expect(find.textContaining('Measure your chest'), findsOneWidget);
    });
  });

  group('goal setup', () {
    Future<List<FitnessGoal>> open(WidgetTester t, {FitnessGoal? initial, double? current = 80}) async {
      final saved = <FitnessGoal>[];
      await _pumpPage(t, GoalSetupPage(
        initial: initial, currentKg: current, imperial: false,
        onSave: (g) async {
          saved.add(g);
          return true;
        },
      ));
      return saved;
    }

    testWidgets('a weight-loss target above your weight is refused', (t) async {
      final saved = await open(t);
      await t.enterText(find.byType(TextField).at(1), '85');
      await t.ensureVisible(find.text('Save goal'));
      await t.tap(find.text('Save goal'));
      await t.pump();
      expect(find.textContaining('needs to be below'), findsOneWidget);
      expect(saved, isEmpty);
    });

    testWidgets('saves a goal with a target, a pace and focus muscles', (t) async {
      final saved = await open(t);
      await t.enterText(find.byType(TextField).at(1), '75');
      await t.ensureVisible(find.text('Quads'));
      await t.tap(find.text('Quads'));
      await t.pump();
      await t.ensureVisible(find.text('Save goal'));
      await t.tap(find.text('Save goal'));
      await t.pumpAndSettle();

      final g = saved.single;
      expect(g.type, GoalType.loseWeight);
      expect(g.startWeightKg, 80);
      expect(g.targetWeightKg, 75);
      expect(g.weeklyRateKg, inInclusiveRange(0.1, 0.8));
      expect(g.focusMuscles, [MuscleGroup.quads]);
    });

    testWidgets('building muscle needs no target', (t) async {
      final saved = await open(t);
      await t.tap(find.text('Build muscle'));
      await t.pump();
      expect(find.text('How fast?'), findsNothing);
      await t.ensureVisible(find.text('Save goal'));
      await t.tap(find.text('Save goal'));
      await t.pumpAndSettle();
      expect(saved.single.type, GoalType.buildMuscle);
      expect(saved.single.targetWeightKg, isNull);
    });

    testWidgets('at most six muscles can be chosen', (t) async {
      await open(t);
      for (final g in MuscleGroup.values.take(7)) {
        await t.ensureVisible(find.text(g.label).last);
        await t.tap(find.text(g.label).last);
        await t.pump();
      }
      expect(find.text('6/6'), findsOneWidget);
    });

    testWidgets('coming from a muscle starts with it chosen', (t) async {
      await _pumpPage(t, GoalSetupPage(
        initial: null, currentKg: 80, imperial: false, preselect: MuscleGroup.triceps,
        onSave: (_) async => true,
      ));
      expect(find.text('1/6'), findsOneWidget);
    });

    testWidgets('a goal can be removed', (t) async {
      var cleared = 0;
      await _pumpPage(t, GoalSetupPage(
        initial: AnalyticsSamples.goal, currentKg: 80, imperial: false,
        onSave: (_) async => true,
        onClear: () async {
          cleared++;
          return true;
        },
      ));
      await t.ensureVisible(find.text('Remove this goal'));
      await t.tap(find.text('Remove this goal'));
      await t.pumpAndSettle();
      expect(cleared, 1);
    });
  });
}
