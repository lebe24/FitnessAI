import 'package:fitness/data/models/onboarding/onboarding_data.dart';
import 'package:fitness/ui/core/routes/app_router.dart';
import 'package:fitness/ui/features/onboarding/views/onboarding_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens (matches profile_page.dart / BeFit dark theme) ───────────────
const _kBg     = Color(0xFF0A0C12);
const _kCard   = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kDim    = Color(0x80FFFFFF);

const _goalOptions = [
  ('Lose Weight',      '🔥', 'Burn fat, reveal your shape'),
  ('Build Muscle',     '💪', 'Add size, strength and definition'),
  ('Maintain Gains',   '⚖️', 'Keep what you have and stay lean'),
  ('Build Aesthetics', '🎨', 'Sculpt a symmetrical, visual physique'),
];

const _experienceOptions = [
  ('Beginner',          'Just starting out — no experience needed'),
  ('Experienced',       'Training consistently for 1–3 years'),
  ('Freak of Nature',   'Elite athlete — pushing every limit'),
  ('God in Human Form', 'Legendary status — you ARE the standard'),
];

/// Lets the user tweak the inputs that drive workout-plan generation
/// (goal, experience, training days, gender, height, weight), persists
/// them as the new onboarding baseline, then routes to the physique
/// photo analyser so a fresh plan can be generated from the updated data.
class AdjustWorkoutPlanPage extends StatefulWidget {
  const AdjustWorkoutPlanPage({super.key});

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
  final _heightCtl = TextEditingController();
  final _weightCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _heightCtl.dispose();
    _weightCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await OnboardingStorage.loadOnboardingData();
    if (data != null) {
      _original   = data;
      _gender     = data.gender;
      _goal       = data.goal;
      _experience = data.experience;
      _days       = data.workoutDays ?? 3;
      if (data.height != null) {
        _heightMetric = !data.height!.toLowerCase().contains('ft') &&
            !data.height!.toLowerCase().contains("'");
        _heightCtl.text = _numericPart(data.height!);
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

  bool get _isValid =>
      _gender != null && _goal != null && _goal!.isNotEmpty && _experience != null;

  Future<void> _saveAndContinue() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in gender, goal and experience before continuing.')),
      );
      return;
    }

    final heightVal = _heightCtl.text.trim();
    final weightVal = _weightCtl.text.trim();

    final updated = _original.copyWith(
      gender: _gender,
      goal: _goal,
      experience: _experience,
      workoutDays: _days,
      height: heightVal.isEmpty ? _original.height : '$heightVal${_heightMetric ? ' cm' : ' ft'}',
      weight: weightVal.isEmpty ? _original.weight : '$weightVal${_weightMetric ? ' kg' : ' lbs'}',
    );

    await OnboardingStorage.saveOnboardingData(updated);
    if (!mounted) return;
    context.push(ScreenPaths.analysis);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Adjust Workout Plan',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kLime))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Text(
                          'Update your stats and preferences below. We\'ll '
                          'rebuild your plan from a fresh physique photo using '
                          'this new information.',
                          style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: _kDim),
                        ).animate().fadeIn(duration: 300.ms),

                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Goal', icon: Icons.flag_outlined),
                        const SizedBox(height: 10),
                        _GoalGrid(selected: _goal, onSelect: (g) => setState(() => _goal = g)),

                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Experience Level', icon: Icons.bar_chart_rounded),
                        const SizedBox(height: 10),
                        _ExperienceList(
                          selected: _experience,
                          onSelect: (e) => setState(() => _experience = e),
                        ),

                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Training Days / Week', icon: Icons.calendar_view_week_rounded),
                        const SizedBox(height: 10),
                        _DaysSelector(selected: _days, onSelect: (d) => setState(() => _days = d)),

                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Gender', icon: Icons.person_outline_rounded),
                        const SizedBox(height: 10),
                        _GenderRow(selected: _gender, onSelect: (g) => setState(() => _gender = g)),

                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Height', icon: Icons.height_rounded),
                        const SizedBox(height: 10),
                        _MeasurementField(
                          controller: _heightCtl,
                          hint: _heightMetric ? 'e.g. 180' : 'e.g. 5.9',
                          unitA: 'cm',
                          unitB: 'ft',
                          isUnitA: _heightMetric,
                          onUnitChanged: (isA) => setState(() => _heightMetric = isA),
                        ),

                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Weight', icon: Icons.monitor_weight_outlined),
                        const SizedBox(height: 10),
                        _MeasurementField(
                          controller: _weightCtl,
                          hint: _weightMetric ? 'e.g. 75' : 'e.g. 165',
                          unitA: 'kg',
                          unitB: 'lbs',
                          isUnitA: _weightMetric,
                          onUnitChanged: (isA) => setState(() => _weightMetric = isA),
                        ),
                      ],
                    ),
                  ),
                  // ── Bottom CTA ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: GestureDetector(
                      onTap: _saveAndContinue,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 54,
                        decoration: BoxDecoration(
                          color: _isValid ? _kLime : _kCard,
                          borderRadius: BorderRadius.circular(16),
                          border: _isValid ? null : Border.all(color: _kBorder),
                          boxShadow: _isValid
                              ? [BoxShadow(color: _kLime.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 6))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded,
                                color: _isValid ? Colors.black : _kDim, size: 19),
                            const SizedBox(width: 8),
                            Text(
                              'Continue to Photo Scan',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _isValid ? Colors.black : _kDim,
                              ),
                            ),
                          ],
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
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 15, color: _kDim),
      const SizedBox(width: 6),
      Text(label.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _kDim, letterSpacing: 0.8)),
    ]);
  }
}

// ── Goal grid ─────────────────────────────────────────────────────────────────────

class _GoalGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _GoalGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: _goalOptions.map((opt) {
        final (label, emoji, desc) = opt;
        final isSelected = selected == label;
        return GestureDetector(
          onTap: () => onSelect(label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? _kLime.withValues(alpha: 0.1) : _kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? _kLime.withValues(alpha: 0.5) : _kBorder,
                  width: isSelected ? 1.5 : 1),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: isSelected ? _kLime : Colors.white)),
              const SizedBox(height: 2),
              Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 10, color: _kDim, height: 1.3)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── Experience list ──────────────────────────────────────────────────────────────

class _ExperienceList extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _ExperienceList({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _experienceOptions.map((opt) {
        final (label, desc) = opt;
        final isSelected = selected == label;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => onSelect(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? _kLime.withValues(alpha: 0.1) : _kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? _kLime.withValues(alpha: 0.5) : _kBorder,
                    width: isSelected ? 1.5 : 1),
              ),
              child: Row(children: [
                Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 18, color: isSelected ? _kLime : _kDim),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: isSelected ? _kLime : Colors.white)),
                    const SizedBox(height: 2),
                    Text(desc, style: GoogleFonts.inter(fontSize: 11, color: _kDim)),
                  ]),
                ),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Days selector (1-7 chips) ─────────────────────────────────────────────────────

class _DaysSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _DaysSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        final day = i + 1;
        final isSelected = selected == day;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: day == 7 ? 0 : 6),
            child: GestureDetector(
              onTap: () => onSelect(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? _kLime : _kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? _kLime : _kBorder),
                ),
                child: Center(
                  child: Text('$day', style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.black : Colors.white)),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Gender row ────────────────────────────────────────────────────────────────────

class _GenderRow extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _GenderRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _GenderOption(
        label: 'Male', icon: Icons.male_rounded,
        isSelected: selected == 'Male', onTap: () => onSelect('Male'),
      )),
      const SizedBox(width: 10),
      Expanded(child: _GenderOption(
        label: 'Female', icon: Icons.female_rounded,
        isSelected: selected == 'Female', onTap: () => onSelect('Female'),
      )),
    ]);
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _GenderOption({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _kLime.withValues(alpha: 0.1) : _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? _kLime.withValues(alpha: 0.5) : _kBorder,
              width: isSelected ? 1.5 : 1),
        ),
        child: Column(children: [
          Icon(icon, size: 22, color: isSelected ? _kLime : _kDim),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: isSelected ? _kLime : Colors.white)),
        ]),
      ),
    );
  }
}

// ── Measurement field with unit toggle ───────────────────────────────────────────

class _MeasurementField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String unitA;
  final String unitB;
  final bool isUnitA;
  final ValueChanged<bool> onUnitChanged;

  const _MeasurementField({
    required this.controller,
    required this.hint,
    required this.unitA,
    required this.unitB,
    required this.isUnitA,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 14, color: _kDim),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          _UnitPill(label: unitA, isSelected: isUnitA, onTap: () => onUnitChanged(true)),
          _UnitPill(label: unitB, isSelected: !isUnitA, onTap: () => onUnitChanged(false)),
        ]),
      ),
    ]);
  }
}

class _UnitPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _UnitPill({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _kLime : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: isSelected ? Colors.black : _kDim)),
      ),
    );
  }
}
