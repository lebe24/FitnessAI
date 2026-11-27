// Design-review entry point for the Analytics screens. Not part of the app: it
// shows each new card and sheet with sample data and nothing behind them.
//
//   flutter run -t lib/analytics_preview.dart -d <device>
//
// On web, open a screen with
// ?screen=overview|free|empty|weightpage|musclepage|goal|muscle|weight|measure|review
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/muscle_focus.dart';
import 'package:fitness/domain/progression/progression_proposal.dart';
import 'package:fitness/ui/features/analytic/analytics_samples.dart';
import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/billing/complimentary_access.dart';
import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/analytic/views/analytics_stat_tile.dart';
import 'package:fitness/ui/features/analytic/views/body/advice_card.dart';
import 'package:fitness/ui/features/analytic/views/body/body_actions.dart';
import 'package:fitness/ui/features/analytic/views/body/body_weight_card.dart';
import 'package:fitness/ui/features/analytic/views/muscle_coverage_card.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/analytic/views/body/goal_card.dart';
import 'package:fitness/ui/features/analytic/views/body/goal_setup_page.dart';
import 'package:fitness/ui/features/analytic/views/body/log_sheets.dart';
import 'package:fitness/ui/features/analytic/views/body/measurements_card.dart';
import 'package:fitness/ui/features/analytic/views/body/muscle_development_card.dart';
import 'package:fitness/ui/features/analytic/views/body/physique_scores_card.dart';
import 'package:fitness/ui/features/analytic/views/body/weight_trend_card.dart';
import 'package:fitness/ui/features/progression/progression_samples.dart';
import 'package:fitness/ui/features/progression/views/progression_review_page.dart';
import 'package:flutter/material.dart';

class _FreeSubs extends SubscriptionService {
  @override
  bool get isPro => false;
}

class _NoComp extends ComplimentaryAccess {
  _NoComp();
  @override
  bool get isGranted => false;
}

void main() {
  // The muscles card asks whether the user has Pro.
  sl.registerSingleton<AccessPolicy>(AccessPolicy(_FreeSubs(), _NoComp()));
  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: kBodyBg),
        builder: (context, child) => ColoredBox(
          color: kBodyBg,
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 390), child: child)),
        ),
        home: const _Home(),
      );
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  bool _imperial = false;

  @override
  void initState() {
    super.initState();
    final screen = Uri.base.queryParameters['screen'];
    if (screen == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (screen) {
        case 'weightpage':
          _page(_PreviewWeightPage(imperial: _imperial));
        case 'musclepage':
          _page(const _PreviewMusclePage());
        case 'goal':
          _goal();
        case 'muscle':
          _muscle(AnalyticsSamples.muscles.firstWhere((m) => m.group == MuscleGroup.quads));
        case 'weight':
          _weight();
        case 'measure':
          _measure();
        case 'review':
          Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => ProgressionReviewPage(proposal: _coached)));
      }
    });
  }

  /// A proposal the coach has reviewed: one approved, one eased, one held.
  ProgressionProposal get _coached {
    final base = ProgressionSamples.ready;
    final c = base.changes;
    final changes = [
      c[0].reviewed(verdict: CoachVerdict.approve, coachReason: 'Ten clean reps twice. This one is earned.'),
      c[1].reviewed(verdict: CoachVerdict.approve),
      c[2].reviewed(
        verdict: CoachVerdict.soften,
        coachReason: 'Shoulders are fresh, but one extra set is plenty this week.',
      ),
      ...c.sublist(3, 5),
      c[5].reviewed(
        verdict: CoachVerdict.veto,
        kind: ChangeKind.hold,
        after: c[5].before,
        badge: 'Held',
        reason: 'Your back is getting a lot this week. Hold the reps for now.',
        coachReason: 'Your back is getting a lot this week. Hold the reps for now.',
        clearUpdated: true,
      ),
      ...c.sublist(6),
    ];
    return base.withCoach(
      changes: changes,
      state: CoachState.reviewed,
      note: 'Good week to push the bench. I eased one change and held another to protect recovery.',
    );
  }

  void _page(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  void _goal() => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => GoalSetupPage(
          initial: null,
          currentKg: 80.2,
          imperial: _imperial,
          onSave: (g) async => true,
        ),
      ));

  void _muscle(MuscleStatus s) => showBodySheet<void>(
        context,
        (_) => MuscleFocusSheet(
          status: s,
          hasGoal: true,
          onSetFocus: (_) async => true,
          onSetGoal: () {},
        ),
      );

  void _weight() => showBodySheet<void>(
        context,
        (_) => LogWeightSheet(
          lastKg: 80.2,
          imperial: _imperial,
          onUnitChanged: (v) => setState(() => _imperial = v),
          onSave: (kg, d, n) async => true,
        ),
      );

  void _measure() => showBodySheet<void>(
        context,
        (_) => LogMeasurementsSheet(
          latestCm: {for (final e in AnalyticsSamples.measurements.entries) e.key: e.value.latestCm},
          imperial: _imperial,
          onUnitChanged: (v) => setState(() => _imperial = v),
          onSave: (cm, d) async => cm.length,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final screen = Uri.base.queryParameters['screen'];
    final empty = screen == 'empty';
    final free = screen == 'free';
    final pro = !free;

    return Scaffold(
      backgroundColor: kBodyBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Text('Analytics', style: bodyHeading(30)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: AnalyticsStatTile(
                  icon: Icons.local_fire_department_rounded,
                  color: kBodyAmber,
                  value: '12',
                  label: 'Streak',
                  sub: 'days in a row',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnalyticsStatTile(
                  icon: Icons.fitness_center_rounded,
                  color: kBodyLime,
                  value: '18',
                  label: 'Workouts',
                  sub: 'this month',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnalyticsStatTile(
                  icon: Icons.timer_outlined,
                  color: kBodyBlue,
                  value: '14h 20m',
                  label: 'Total Time',
                  sub: 'logged',
                ),
              ),
            ]),
            const SizedBox(height: 16),
            BodyWeightCard(
              pro: pro,
              kg: pro && !empty ? 80.2 : (free ? 78.4 : null),
              weights: pro && !empty ? AnalyticsSamples.weights : const [],
              progress: pro && !empty ? AnalyticsSamples.progress : null,
              targetKg: pro && !empty ? AnalyticsSamples.goal.targetWeightKg : null,
              imperial: _imperial,
              now: AnalyticsSamples.now,
              onUnitChanged: (v) => setState(() => _imperial = v),
              onOpen: () => _page(_PreviewWeightPage(imperial: _imperial)),
              onQuickLog: _weight,
            ),
            const SizedBox(height: 16),
            // Stand-in for the workout duration and volume charts above it.
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kBodyCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBodyBorder),
              ),
              child: Text('Workout Duration and Training Volume', style: bodyText(12, color: kBodyMuted)),
            ),
            const SizedBox(height: 16),
            MuscleCoverageCard(
              sessions: const [],
              isLoading: false,
              onOpenDevelopment: () => _page(const _PreviewMusclePage()),
            ),
          ],
        ),
      ),
    );
  }
}

/// The body-weight page with sample data and nothing behind it.
class _PreviewWeightPage extends StatefulWidget {
  final bool imperial;
  const _PreviewWeightPage({required this.imperial});

  @override
  State<_PreviewWeightPage> createState() => _PreviewWeightPageState();
}

class _PreviewWeightPageState extends State<_PreviewWeightPage> {
  late bool _imperial = widget.imperial;

  @override
  Widget build(BuildContext context) {
    return BodyPageScaffold(
      title: 'Body weight',
      subtitle: 'Your goal, trend and measurements',
      children: [
        GoalCard(
          progress: AnalyticsSamples.progress,
          imperial: _imperial,
          now: AnalyticsSamples.now,
          onSetGoal: () {},
          onLogWeight: () {},
        ),
        const SizedBox(height: 16),
        WeightTrendCard(
          weights: AnalyticsSamples.weights,
          targetKg: AnalyticsSamples.goal.targetWeightKg,
          imperial: _imperial,
          now: AnalyticsSamples.now,
          onUnitChanged: (v) => setState(() => _imperial = v),
          onLog: () {},
        ),
        const SizedBox(height: 16),
        AdviceCard(
          advice: AnalyticsSamples.advice,
          hasGoal: true,
          loading: false,
          error: null,
          onRefresh: () {},
          onSetGoal: () {},
        ),
        const SizedBox(height: 16),
        MeasurementsCard(
          summary: AnalyticsSamples.measurements,
          imperial: _imperial,
          goalType: GoalType.loseWeight,
          onUnitChanged: (v) => setState(() => _imperial = v),
          onLog: () {},
          onTapSite: (_) {},
        ),
      ],
    );
  }
}

/// The muscle development page with sample data and nothing behind it.
class _PreviewMusclePage extends StatelessWidget {
  const _PreviewMusclePage();

  @override
  Widget build(BuildContext context) {
    final strengths = [for (final m in AnalyticsSamples.muscles) if (m.level == MuscleLevel.strong) m]
      ..sort((a, b) => b.score.compareTo(a.score));
    final focus = [for (final m in AnalyticsSamples.muscles) if (m.level == MuscleLevel.focus) m]
      ..sort((a, b) => a.score.compareTo(b.score));
    return BodyPageScaffold(
      title: 'Muscle development',
      subtitle: 'Strong, average and focus muscles',
      children: [
        MuscleDevelopmentCard(muscles: AnalyticsSamples.muscles, onSelect: (_) {}),
        const SizedBox(height: 16),
        StrengthsFocusCard(strengths: strengths, focusAreas: focus, onSelect: (_) {}),
        const SizedBox(height: 16),
        PhysiqueScoresCard(scan: AnalyticsSamples.scan),
      ],
    );
  }
}
