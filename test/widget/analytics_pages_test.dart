import 'dart:io';

import 'package:fitness/data/repositories/body_tracking_repository.dart';
import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/billing/complimentary_access.dart';
import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:fitness/data/services/workout_log/exercise_history_service.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/analytic/view_models/analytics_view_model.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/analytic/views/body/body_weight_page.dart';
import 'package:fitness/ui/features/analytic/views/body/log_sheets.dart';
import 'package:fitness/ui/features/analytic/views/body/goal_card.dart';
import 'package:fitness/ui/features/analytic/views/body/measurements_card.dart';
import 'package:fitness/ui/features/analytic/views/body/muscle_development_card.dart';
import 'package:fitness/ui/features/analytic/views/body/muscle_development_page.dart';
import 'package:fitness/ui/features/analytic/views/body/physique_scores_card.dart';
import 'package:fitness/ui/features/analytic/views/body/weight_trend_card.dart';
import 'package:fitness/ui/features/analytic/views/muscle_coverage_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../fakes/fake_body_tracking.dart';

class _Subs extends SubscriptionService {
  @override
  bool get isPro => false;
}

class _NoComp extends ComplimentaryAccess {
  _NoComp();
  @override
  bool get isGranted => false;
}

AnalyticsViewModel _vm() => AnalyticsViewModel(
      repo: BodyTrackingRepository(remote: FakeBodyRemote(), store: MemoryBodyStore()),
      history: ExerciseHistoryService(fetch: () async => const []),
      latestScan: () async => null,
      canUse: (_) => true,
    );

Future<void> _pumpPage(WidgetTester t, Widget page) async {
  t.view.physicalSize = const Size(400, 3200);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(home: page));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // Open the boxes up front, outside the test's fake clock, so the pages find
    // them already open.
    Hive.init(Directory.systemTemp.createTempSync('analytics_pages').path);
    await Hive.openBox('app_settings');
    await Hive.openBox('onboarding_data');
  });

  setUp(() async {
    await sl.reset();
    sl.registerSingleton<AnalyticsViewModel>(_vm());
    sl.registerSingleton<AccessPolicy>(AccessPolicy(_Subs(), _NoComp()));
  });
  tearDown(() async => sl.reset());

  testWidgets('the body weight page holds the goal, trend, advice and measurements', (t) async {
    await _pumpPage(t, const BodyWeightPage());

    expect(find.text('Body weight'), findsOneWidget);
    expect(find.text('Weight trend'), findsOneWidget);
    expect(find.byType(GoalCard), findsOneWidget);
    expect(find.byType(WeightTrendCard), findsOneWidget);
    expect(find.text('Coach advice'), findsOneWidget);
    expect(find.byType(MeasurementsCard), findsOneWidget);
    // The muscle cards belong to the other page.
    expect(find.byType(MuscleDevelopmentCard), findsNothing);
  });

  testWidgets('the muscle page holds the map, strengths and physique scores', (t) async {
    await _pumpPage(t, const MuscleDevelopmentPage());

    expect(find.text('Muscle development'), findsWidgets);
    expect(find.byType(MuscleDevelopmentCard), findsOneWidget);
    expect(find.byType(PhysiqueScoresCard), findsOneWidget);
    expect(find.byType(GoalCard), findsNothing);
  });

  testWidgets('the back button leaves the page', (t) async {
    t.view.physicalSize = const Size(400, 3200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const MuscleDevelopmentPage())),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.byType(MuscleDevelopmentPage), findsOneWidget);

    await t.tap(find.bySemanticsLabel('Back'));
    await t.pumpAndSettle();
    expect(find.byType(MuscleDevelopmentPage), findsNothing);
  });

  testWidgets('the muscles trained card opens the development page from its footer', (t) async {
    var opened = 0;
    t.view.physicalSize = const Size(400, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MuscleCoverageCard(
            sessions: const [],
            isLoading: false,
            onOpenDevelopment: () => opened++,
          ),
        ),
      ),
    ));
    await t.pump();

    await t.tap(find.text('Strengths, focus areas and scores'));
    expect(opened, 1);
  });

  testWidgets('without a handler the muscles card shows no way in', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(body: MuscleCoverageCard(sessions: [], isLoading: false)),
    ));
    await t.pump();
    expect(find.text('Strengths, focus areas and scores'), findsNothing);
  });

  testWidgets('opening a page while another screen listens to the model does not rebuild mid-build',
      (t) async {
    final vm = sl<AnalyticsViewModel>();
    t.view.physicalSize = const Size(400, 3200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const BodyWeightPage())),
            child: Text(vm.loading ? 'loading' : 'open'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();

    expect(t.takeException(), isNull);
    expect(find.byType(BodyWeightPage), findsOneWidget);
  });

  keyboardTests();
}

/// The keyboard must never cover a sheet. A page inside a Scaffold has the
/// keyboard height removed from its context, so a sheet has to read it from its
/// own route.
void keyboardTests() {
  testWidgets('a body sheet stays above the keyboard', (t) async {
    t.view.physicalSize = const Size(400, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    addTearDown(t.view.resetViewInsets);

    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showBodySheet<void>(
              context,
              (_) => LogWeightSheet(
                lastKg: 80,
                imperial: false,
                onUnitChanged: (_) {},
                onSave: (kg, d, n) async => true,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();

    t.view.viewInsets = const FakeViewPadding(bottom: 320);
    await t.pumpAndSettle();

    final save = t.getRect(find.text('Save'));
    expect(save.bottom, lessThanOrEqualTo(800 - 320));
  });
}
