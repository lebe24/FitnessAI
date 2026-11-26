import 'package:fitness/data/repositories/body_tracking_repository.dart';
import 'package:fitness/data/services/workout_log/exercise_history_service.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/ui/features/analytic/view_models/analytics_view_model.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/analytic/views/body/body_weight_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../fakes/fake_body_tracking.dart';

AnalyticsViewModel _vm(FakeBodyRemote remote, {required bool pro}) => AnalyticsViewModel(
      repo: BodyTrackingRepository(remote: remote, store: MemoryBodyStore()),
      history: ExerciseHistoryService(fetch: () async => const []),
      latestScan: () async => null,
      canUse: (_) => pro,
    );

Future<void> _pump(
  WidgetTester t,
  AnalyticsViewModel vm, {
  double? legacyKg,
  bool imperial = false,
  VoidCallback? onOpen,
  VoidCallback? onQuickLog,
}) async {
  t.view.physicalSize = const Size(400, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final pro = vm.hasBodyTracking;
  await t.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BodyWeightCard(
          pro: pro,
          kg: (pro ? vm.latestWeight?.weightKg : null) ?? legacyKg,
          weights: pro ? vm.weights : const [],
          progress: pro ? vm.progress : null,
          targetKg: vm.goal?.targetWeightKg,
          imperial: imperial,
          onUnitChanged: (_) {},
          onOpen: onOpen ?? () {},
          onQuickLog: onQuickLog ?? () {},
        ),
      ),
    ),
  ));
  await t.pumpAndSettle();
}

List<BodyWeightEntry> _month() {
  final today = DateTime.now();
  final d = DateTime(today.year, today.month, today.day);
  return [
    for (var i = 0; i < 8; i++)
      BodyWeightEntry(date: d.subtract(Duration(days: (7 - i) * 3)), weightKg: 82 - i * 0.4),
  ];
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('body weight card', () {
    testWidgets('free: shows the saved weight, no chart, and opens the way in', (t) async {
      var opened = 0;
      await _pump(t, _vm(FakeBodyRemote(), pro: false), legacyKg: 72.5, onOpen: () => opened++);

      expect(find.text('72.5 kg'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
      expect(find.text('Pro draws your weight over time'), findsOneWidget);

      await t.tap(find.text('Track a goal and see your trend'));
      expect(opened, 1);
    });

    testWidgets('pro: draws the last month of weigh-ins', (t) async {
      final remote = FakeBodyRemote()..weights.addAll(_month());
      final vm = _vm(remote, pro: true);
      await vm.load();
      await _pump(t, vm);

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('PRO'), findsNothing);
      expect(find.text('Goal, trend and measurements'), findsOneWidget);
    });

    testWidgets('pro with a goal shows where it stands', (t) async {
      final remote = FakeBodyRemote()
        ..weights.addAll(_month())
        ..goal = const FitnessGoal(
            id: 'g', type: GoalType.loseWeight, startWeightKg: 82, targetWeightKg: 76, weeklyRateKg: 0.5);
      final vm = _vm(remote, pro: true);
      await vm.load();
      await _pump(t, vm);

      expect(find.byType(StatusPill), findsOneWidget);
    });

    testWidgets('pro with one weigh-in asks for another', (t) async {
      final today = DateTime.now();
      final remote = FakeBodyRemote()
        ..weights.add(BodyWeightEntry(date: DateTime(today.year, today.month, today.day), weightKg: 80));
      final vm = _vm(remote, pro: true);
      await vm.load();
      await _pump(t, vm);

      expect(find.byType(LineChart), findsNothing);
      expect(find.text('One more weigh-in draws your line'), findsOneWidget);
      expect(find.text('80 kg'), findsOneWidget);
    });

    testWidgets('speaks in pounds when asked', (t) async {
      await _pump(t, _vm(FakeBodyRemote(), pro: false), legacyKg: 80, imperial: true);
      expect(find.text('176.4 lb'), findsOneWidget);
    });

    testWidgets('the pencil logs without opening the page', (t) async {
      var opened = 0, logged = 0;
      await _pump(t, _vm(FakeBodyRemote(), pro: false),
          legacyKg: 72.5, onOpen: () => opened++, onQuickLog: () => logged++);

      await t.tap(find.byIcon(Icons.edit_rounded));
      expect(logged, 1);
      expect(opened, 0);
    });


    testWidgets('the weight is white, not lime', (t) async {
      await _pump(t, _vm(FakeBodyRemote(), pro: false), legacyKg: 72.5);
      final style = t.widget<Text>(find.text('72.5 kg')).style!;
      expect(style.color, Colors.white);
    });
  });
}
