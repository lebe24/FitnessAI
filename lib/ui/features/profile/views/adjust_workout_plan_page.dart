import 'package:fitness/data/models/onboarding/onboarding_data.dart';
import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/plan_analytics.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/domain/models/height_text.dart';
import 'package:fitness/ui/core/routes/app_router.dart';
import 'package:fitness/ui/core/widgets/centered_title_bar.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/onboarding/views/onboarding_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _kLime = kBodyLime;
const _kDim = Color(0x80FFFFFF);
const _kSelectedGoal = Color(0xFF161B16);
const _kTile = Color(0xFF1B2030);
const _kTileSelected = Color(0xFF222A12);

const _goalOptions = [
  ('Lose Weight', '🔥', 'Burn fat, reveal your shape'),
  ('Build Muscle', '💪', 'Add size, strength and definition'),
  ('Maintain Gains', '⚖️', 'Keep what you have and stay lean'),
  ('Build Aesthetics', '🎨', 'Sculpt a symmetrical, visual physique'),
];

/// Only the labels are shown. They are the strings that are stored and that the
/// backend's prompt expects, so they are not renamed.
const _experienceOptions = [
  ('Beginner', 'Just starting out — no experience needed'),
  ('Experienced', 'Training consistently for 1–3 years'),
  ('Freak of Nature', 'Elite athlete — pushing every limit'),
  ('God in Human Form', 'Legendary status — you ARE the standard'),
];

const _genderOptions = ['Female', 'Male', 'Other'];

/// Lets the user tweak the inputs that drive workout-plan generation
/// (goal, experience, training days, gender, height, weight), persists
/// them as the new onboarding baseline, then routes to the physique
/// photo analyser so a fresh plan can be generated from the updated data.
class AdjustWorkoutPlanPage extends StatefulWidget {
  /// Where the saved answers come from. Defaults to the onboarding storage;
  /// tests and the preview pass their own.
  final Future<OnboardingData?> Function()? load;

  /// Where the new answers go. Defaults to the onboarding storage.
  final Future<void> Function(OnboardingData data)? save;

  /// What happens after saving. Defaults to opening the photo scan.
  final VoidCallback? onContinue;

  const AdjustWorkoutPlanPage({
    super.key,
    this.load,
    this.save,
    this.onContinue,
  });

  @override
  State<AdjustWorkoutPlanPage> createState() => _AdjustWorkoutPlanPageState();
}

class _AdjustWorkoutPlanPageState extends State<AdjustWorkoutPlanPage> {
  bool _loading = true;
  OnboardingData _original = const OnboardingData();

  String? _gender;
  String? _goal;
  String? _experience;
  int _days = 3;
  bool _heightMetric = true; // cm vs ft/in
  bool _weightMetric = true; // kg vs lbs
  // Metric height is one number in _heightCtl. Imperial height is feet in
  // _heightCtl and inches in _inchesCtl.
  final _heightCtl = TextEditingController();
  final _inchesCtl = TextEditingController();
  final _weightCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Analytics.screen('adjust_plan');
    _load();
  }

  @override
  void dispose() {
    _heightCtl.dispose();
    _inchesCtl.dispose();
    _weightCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await (widget.load ?? OnboardingStorage.loadOnboardingData)();
    if (data != null) {
      _original = data;
      _gender = data.gender;
      _goal = data.goal;
      _experience = data.experience;
      _days = data.workoutDays ?? 3;
      if (data.height != null) {
        // Onboarding wrote `1.8 m` or `5 ft 10 in`; this screen wrote `178 cm`
        // or `5.9 ft`. Read them all as centimetres, then show them in the
        // unit they were written in.
        _heightMetric = !HeightText.isImperial(data.height);
        final cm = HeightText.toCm(data.height);
        if (cm != null) _showHeight(cm);
      }
      if (data.weight != null) {
        _weightMetric = !data.weight!.toLowerCase().contains('lb');
        _weightCtl.text = _numericPart(data.weight!);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _numericPart(String value) =>
      RegExp(r'[\d.]+').firstMatch(value)?.group(0) ?? '';

  /// Puts [cm] into the height boxes in the unit now selected.
  void _showHeight(double cm) {
    if (_heightMetric) {
      _heightCtl.text = cm.round().toString();
      _inchesCtl.clear();
    } else {
      final (ft, inch) = HeightText.feetInches(cm);
      _heightCtl.text = '$ft';
      _inchesCtl.text = '$inch';
    }
  }

  /// The height typed so far, in centimetres. Null when the boxes are empty or
  /// not numbers.
  double? _typedHeightCm() {
    if (_heightMetric) return double.tryParse(_heightCtl.text.trim());
    final ft = int.tryParse(_heightCtl.text.trim());
    if (ft == null) return null;
    return HeightText.fromFeetInches(ft, int.tryParse(_inchesCtl.text.trim()) ?? 0);
  }

  /// Switches height unit and converts what is typed, so 178 cm becomes
  /// 5 ft 10 in rather than "178 ft".
  void _setHeightMetric(bool metric) {
    if (metric == _heightMetric) return;
    final cm = _typedHeightCm();
    setState(() {
      _heightMetric = metric;
      if (cm != null) {
        _showHeight(cm);
      } else {
        _heightCtl.clear();
        _inchesCtl.clear();
      }
    });
  }

  /// Switches weight unit and converts what is typed.
  void _setWeightMetric(bool metric) {
    if (metric == _weightMetric) return;
    final v = double.tryParse(_weightCtl.text.trim());
    setState(() {
      _weightMetric = metric;
      if (v != null) {
        final converted = metric ? BodyUnits.lbToKg(v) : BodyUnits.kgToLb(v);
        final text = converted.toStringAsFixed(1);
        _weightCtl.text = text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
      }
    });
  }

  /// The height to save, `null` to keep the stored one, or an error message
  /// when what was typed cannot be a height.
  (String? value, String? error) _heightToSave() {
    final typed = _heightCtl.text.trim();
    if (typed.isEmpty) return (null, null);
    if (_heightMetric) {
      final cm = double.tryParse(typed);
      if (cm == null || cm < HeightText.minCm || cm > HeightText.maxCm) {
        return (null, 'Enter your height in centimetres, like 178.');
      }
      return (HeightText.storedMetric(cm), null);
    }
    final ft = int.tryParse(typed);
    final inch = _inchesCtl.text.trim().isEmpty ? 0 : int.tryParse(_inchesCtl.text.trim());
    if (ft == null || inch == null || ft < 1 || ft > 8 || inch < 0 || inch > 11) {
      return (null, 'Enter your height as feet and inches, like 5 and 10.');
    }
    return (HeightText.storedImperial(ft, inch), null);
  }

  bool get _isValid =>
      _gender != null &&
      _goal != null &&
      _goal!.isNotEmpty &&
      _experience != null;

  Future<void> _saveAndContinue() async {
    if (!_isValid) {
      PlanAnalytics.adjustBlocked('missing_fields');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in gender, goal and experience before continuing.',
          ),
        ),
      );
      return;
    }

    final (height, heightError) = _heightToSave();
    if (heightError != null) {
      PlanAnalytics.adjustBlocked('invalid_height');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(heightError)));
      return;
    }
    final weightVal = _weightCtl.text.trim();

    final updated = _original.copyWith(
      gender: _gender,
      goal: _goal,
      experience: _experience,
      workoutDays: _days,
      height: height ?? _original.height,
      weight: weightVal.isEmpty
          ? _original.weight
          : '$weightVal${_weightMetric ? ' kg' : ' lbs'}',
    );

    PlanAnalytics.adjustSubmitted(
      goal: _goal,
      experience: _experience,
      days: _days,
      changedGoal: _goal != _original.goal,
      changedExperience: _experience != _original.experience,
      changedDays: _days != (_original.workoutDays ?? 3),
      heightMetric: _heightMetric,
      weightMetric: _weightMetric,
    );
    await (widget.save ?? OnboardingStorage.saveOnboardingData)(updated);
    if (!mounted) return;
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      context.push(ScreenPaths.analysis);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBodyBg,
      body: SafeArea(
        child: Column(
          children: [
            const CenteredTitleBar(title: 'Adjust Workout Plan'),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kLime),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        const _SectionLabel('Goal'),
                        const SizedBox(height: 14),
                        _GoalGrid(
                          selected: _goal,
                          onSelect: (g) => setState(() => _goal = g),
                        ),

                        const SizedBox(height: 26),
                        const _SectionLabel('Experience Level'),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final (label, _) in _experienceOptions)
                              _PillChip(
                                label: label,
                                selected: _experience == label,
                                onTap: () =>
                                    setState(() => _experience = label),
                              ),
                          ],
                        ),

                        const SizedBox(height: 26),
                        const _SectionLabel('Training Days / Week'),
                        const SizedBox(height: 14),
                        _DaysSelector(
                          selected: _days,
                          onSelect: (d) => setState(() => _days = d),
                        ),

                        const SizedBox(height: 26),
                        const _SectionLabel('Gender'),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final g in _genderOptions)
                              _PillChip(
                                label: g,
                                selected: _gender == g,
                                onTap: () => setState(() => _gender = g),
                              ),
                          ],
                        ),

                        const SizedBox(height: 26),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _MeasurementField(
                                label: 'Height',
                                controller: _heightCtl,
                                secondController: _heightMetric ? null : _inchesCtl,
                                hint: _heightMetric ? '178' : '5',
                                unitA: 'cm',
                                unitB: 'ft',
                                isUnitA: _heightMetric,
                                onUnitChanged: _setHeightMetric,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _MeasurementField(
                                label: 'Weight',
                                controller: _weightCtl,
                                hint: _weightMetric ? '78' : '165',
                                unitA: 'kg',
                                unitB: 'lbs',
                                isUnitA: _weightMetric,
                                onUnitChanged: _setWeightMetric,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            // ── Bottom CTA ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Semantics(
                button: true,
                enabled: _isValid,
                child: GestureDetector(
                  onTap: _saveAndContinue,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isValid ? _kLime : kBodyCard,
                      borderRadius: BorderRadius.circular(28),
                      border: _isValid ? null : Border.all(color: kBodyBorder),
                    ),
                    child: Text(
                      'Continue to Photo Scan',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _isValid ? kBodyBg : _kDim,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: bodyText(
      12,
      color: kBodyMuted,
      weight: FontWeight.w600,
    ).copyWith(letterSpacing: 0.5),
  );
}

// ── Goal grid ─────────────────────────────────────────────────────────────────────

class _GoalGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _GoalGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    // The cards grow with the phone's text size so larger text is not clipped.
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 106 + (scale - 1) * 60,
      ),
      children: _goalOptions.map((opt) {
        final (label, emoji, desc) = opt;
        final isSelected = selected == label;
        return Semantics(
          button: true,
          selected: isSelected,
          child: GestureDetector(
            onTap: () => onSelect(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              decoration: BoxDecoration(
                color: isSelected ? _kSelectedGoal : kBodyCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _kLime : kBodyBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? _kTileSelected : _kTile,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyHeading(13).copyWith(height: 1.15),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: bodyText(
                      10.5,
                      color: kBodyMuted,
                      weight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Pill chip (experience, gender) ────────────────────────────────────────────────

class _PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? _kLime : kBodyChip,
            borderRadius: BorderRadius.circular(19),
            border: selected ? null : Border.all(color: kBodyBorder),
          ),
          // widthFactor so the chip hugs its text instead of stretching to the
          // full width it is offered.
          child: Center(
            widthFactor: 1,
            child: Text(label, style: bodyText(13, color: selected ? kBodyBg : kBodySoft)),
          ),
        ),
      ),
    );
  }
}

// ── Days selector (1-7 circles) ───────────────────────────────────────────────────

class _DaysSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _DaysSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // 40px circles when there is room, smaller on a narrow phone.
        final size = ((box.maxWidth - 6 * 4) / 7).clamp(30.0, 40.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day = i + 1;
            final isSelected = selected == day;
            return Semantics(
              button: true,
              selected: isSelected,
              label: '$day ${day == 1 ? 'day' : 'days'} a week',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => onSelect(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? _kLime : kBodyChip,
                    border: isSelected ? null : Border.all(color: kBodyBorder),
                  ),
                  child: Text(
                    '$day',
                    style: bodyHeading(
                      14,
                      color: isSelected ? kBodyBg : kBodySoft,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Measurement field with unit toggle ───────────────────────────────────────────

class _MeasurementField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  /// A second box, for inches beside feet. Null for a single number.
  final TextEditingController? secondController;
  final String hint;
  final String unitA;
  final String unitB;
  final bool isUnitA;
  final ValueChanged<bool> onUnitChanged;

  const _MeasurementField({
    required this.label,
    required this.controller,
    this.secondController,
    required this.hint,
    required this.unitA,
    required this.unitB,
    required this.isUnitA,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    // The switch names the unit you are in; feet and inches show as `ft`.
    final unit = isUnitA ? unitA : unitB;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: bodyText(12, color: kBodyMuted)),
        const SizedBox(height: 10),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: kBodyCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBodyBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: secondController == null
                    ? _NumberBox(controller: controller, hint: hint, padLeft: 16)
                    // Feet and inches: two small boxes, scaled down together on
                    // a narrow phone.
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 30,
                              child: _NumberBox(controller: controller, hint: hint, whole: true),
                            ),
                            Text('ft', style: bodyText(13, color: kBodyMuted, weight: FontWeight.w400)),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 30,
                              child: _NumberBox(controller: secondController!, hint: '10', whole: true),
                            ),
                            Text('in', style: bodyText(13, color: kBodyMuted, weight: FontWeight.w400)),
                          ],
                        ),
                      ),
              ),
              // The design shows the unit as plain text. It is also the switch
              // between metric and imperial, which this screen still needs.
              Semantics(
                button: true,
                label:
                    'Unit: $unit. Tap to switch to ${isUnitA ? unitB : unitA}.',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onUnitChanged(!isUnitA),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          unit,
                          style: bodyText(
                            13,
                            color: _kLime,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.unfold_more_rounded,
                          size: 14,
                          color: _kLime,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A plain number box inside a measurement field.
class _NumberBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final double padLeft;

  /// Whole numbers only (feet, inches) rather than decimals.
  final bool whole;

  const _NumberBox({
    required this.controller,
    required this.hint,
    this.padLeft = 0,
    this.whole = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !whole),
      textAlign: whole ? TextAlign.center : TextAlign.start,
      // White on the dark field. It used to be black, which could not be read.
      style: bodyText(14, weight: FontWeight.w400),
      cursorColor: _kLime,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: bodyText(14, color: _kDim, weight: FontWeight.w400),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.fromLTRB(padLeft, 14, whole ? 0 : 4, 14),
      ),
    );
  }
}
