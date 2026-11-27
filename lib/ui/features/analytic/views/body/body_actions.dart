import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/body/muscle_focus.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/analytic/view_models/analytics_view_model.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/analytic/views/body/goal_setup_page.dart';
import 'package:fitness/ui/features/analytic/views/body/log_sheets.dart';
import 'package:fitness/ui/features/analytic/views/body/measurements_card.dart';
import 'package:fitness/ui/features/analytic/views/body/muscle_development_card.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// The kg / lb choice, kept in one place so the Analytics card and both pages
/// opened from it always agree.
class BodyUnitPref {
  const BodyUnitPref._();

  static const _box = 'app_settings';
  static const _key = 'units_imperial';

  /// The saved choice. Until one is made it follows the unit the older weight
  /// card was using.
  static Future<bool?> load() async {
    try {
      final box = await Hive.openBox(_box);
      final v = box.get(_key);
      if (v is bool) return v;
      final legacy = (await Hive.openBox('onboarding_data')).get('logged_body_weight_unit');
      return legacy is String ? legacy.toLowerCase().startsWith('lb') : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(bool imperial) async {
    try {
      final box = await Hive.openBox(_box);
      await box.put(_key, imperial);
    } catch (_) {}
  }
}

/// What the body-weight and muscle pages share: loading the data once, the
/// unit, and the sheets and screens they open.
mixin BodyActions<T extends StatefulWidget> on State<T> {
  final AnalyticsViewModel vm = sl<AnalyticsViewModel>();
  bool imperial = false;
  bool _started = false;

  /// Called with the weight in kilograms after a weigh-in is saved, so the
  /// older single-value weight card stays in step.
  ValueChanged<double>? get onWeightLogged => null;

  /// Call from initState.
  void startBodyActions() {
    BodyUnitPref.load().then((v) {
      if (mounted && v != null) setState(() => imperial = v);
    });
    _load();
  }

  Future<void> _load() async {
    if (_started || !vm.hasBodyTracking) return;
    _started = true;
    await vm.load();
    if (mounted && vm.goal != null && vm.advice == null && vm.hasGoalAdvice) {
      await vm.refreshAdvice();
    }
  }

  Future<void> setImperial(bool v) async {
    setState(() => imperial = v);
    await BodyUnitPref.save(v);
  }

  Future<void> openGoal({MuscleGroup? preselect}) async {
    await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => GoalSetupPage(
        initial: vm.goal,
        currentKg: vm.latestWeight?.weightKg,
        imperial: imperial,
        preselect: preselect,
        onSave: vm.saveGoal,
        onClear: vm.goal == null ? null : vm.clearGoal,
      ),
    ));
    // A new goal changes what the advice should say.
    if (mounted && vm.goal != null && vm.hasGoalAdvice) vm.refreshAdvice(force: true);
  }

  void logWeight() {
    showBodySheet<void>(
      context,
      (_) => LogWeightSheet(
        lastKg: vm.latestWeight?.weightKg,
        imperial: imperial,
        onUnitChanged: setImperial,
        onSave: (kg, date, note) async {
          final ok = await vm.logWeight(kg, date: date, note: note);
          if (ok) onWeightLogged?.call(kg);
          return ok;
        },
      ),
    );
  }

  void logMeasurements() {
    showBodySheet<void>(
      context,
      (_) => LogMeasurementsSheet(
        latestCm: {for (final e in vm.measurementSummary.entries) e.key: e.value.latestCm},
        imperial: imperial,
        onUnitChanged: setImperial,
        onSave: (cm, date) => vm.logMeasurements(cm, date: date),
      ),
    );
  }

  void openSite(MeasurementSite site) {
    showBodySheet<void>(
      context,
      (_) => MeasurementHistorySheet(
        site: site,
        entries: [for (final m in vm.measurements) if (m.site == site) m],
        imperial: imperial,
        // Without an id the reading is still only on this device.
        onDelete: (m) async => vm.deleteMeasurement(m),
      ),
    );
  }

  void openMuscle(MuscleStatus status) {
    showBodySheet<void>(
      context,
      (_) => MuscleFocusSheet(
        status: status,
        hasGoal: vm.goal != null,
        onSetFocus: (focus) => vm.setFocus(status.group, focus: focus),
        onSetGoal: () => openGoal(preselect: status.group),
      ),
    );
  }
}

/// The frame both pages use: a back button, a title and the scrolling body.
class BodyPageScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? floatingActionButton;

  const BodyPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBodyBg,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Back',
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBodyBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: bodyHeading(20)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: bodyText(12, color: kBodyMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                // Room to scroll the last card clear of a floating button.
                padding: EdgeInsets.fromLTRB(16, 4, 16, floatingActionButton == null ? 40 : 110),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OfflineNote extends StatelessWidget {
  const OfflineNote({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          const Icon(Icons.cloud_off_rounded, size: 14, color: kBodyMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Offline. Showing saved data. Anything you log syncs when you are back online.',
                style: bodyText(11.5, color: kBodyMuted, height: 1.4)),
          ),
        ]),
      );
}
