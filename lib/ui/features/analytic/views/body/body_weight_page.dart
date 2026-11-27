import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/ui/features/analytic/views/body/advice_card.dart';
import 'package:fitness/ui/features/analytic/views/body/body_actions.dart';
import 'package:fitness/ui/features/analytic/views/body/goal_card.dart';
import 'package:fitness/ui/features/analytic/views/body/measurements_card.dart';
import 'package:fitness/ui/features/analytic/views/body/weight_trend_card.dart';
import 'package:flutter/material.dart';

/// Everything about the user's weight and goal: the goal, the full trend chart,
/// coach advice and measurements. Opened from the Body Weight card on the
/// Analytics tab.
class BodyWeightPage extends StatefulWidget {
  final ValueChanged<double>? onWeightLogged;
  const BodyWeightPage({super.key, this.onWeightLogged});

  @override
  State<BodyWeightPage> createState() => _BodyWeightPageState();
}

class _BodyWeightPageState extends State<BodyWeightPage> with BodyActions<BodyWeightPage> {
  @override
  ValueChanged<double>? get onWeightLogged => widget.onWeightLogged;

  @override
  void initState() {
    super.initState();
    Analytics.screen('body_weight');
    startBodyActions();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final now = DateTime.now();
        return BodyPageScaffold(
          title: 'Body weight',
          subtitle: 'Your goal, trend and measurements',
          children: [
            if (vm.offline) const OfflineNote(),
            GoalCard(
              progress: vm.progress,
              imperial: imperial,
              now: now,
              onSetGoal: openGoal,
              onLogWeight: logWeight,
            ),
            const SizedBox(height: 16),
            WeightTrendCard(
              weights: vm.weights,
              targetKg: vm.goal?.targetWeightKg,
              imperial: imperial,
              now: now,
              onUnitChanged: setImperial,
              onLog: logWeight,
            ),
            const SizedBox(height: 16),
            AdviceCard(
              advice: vm.advice,
              hasGoal: vm.goal != null,
              loading: vm.adviceLoading,
              error: vm.adviceError,
              onRefresh: () => vm.refreshAdvice(force: true),
              onSetGoal: openGoal,
            ),
            const SizedBox(height: 16),
            MeasurementsCard(
              summary: vm.measurementSummary,
              imperial: imperial,
              goalType: vm.goal?.type,
              onUnitChanged: setImperial,
              onLog: logMeasurements,
              onTapSite: openSite,
            ),
          ],
        );
      },
    );
  }
}
