import 'package:fitness/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:fitness/ui/features/onboarding/views/share_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _lime = Color(0xFFCCFF00);

class HeightAndWeightStep extends StatefulWidget {
  const HeightAndWeightStep({super.key});

  @override
  State<HeightAndWeightStep> createState() => _HeightAndWeightStepState();
}

class _HeightAndWeightStepState extends State<HeightAndWeightStep> {
  bool _heightInteracted = false;
  bool _weightInteracted = false;

  final _feetList   = List.generate(8, (i) => i + 2);
  final _inchList   = List.generate(12, (i) => i);
  final _meterList  = List.generate(16, (i) => 1.0 + i * 0.1);
  final _kgList     = List.generate(100, (i) => i + 40);
  final _lbsList    = List.generate(200, (i) => i + 80);

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (context, vm, _) {
        final isMetric = vm.isMetric;

        return BaseStepLayout(
          title: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              children: const [
                TextSpan(text: 'Height &\n'),
                TextSpan(text: 'Weight', style: TextStyle(backgroundColor: _lime, color: Colors.black)),
              ],
            ),
          ).animate().fadeIn(duration: 900.ms).slideY(begin: 0.2, end: 0),
          subtitle: 'Used for calorie targets and load calculations',
          children: [
            // Unit toggle
            _UnitToggle(isMetric: isMetric, onToggle: vm.toggleUnitSystem),

            // ── Height picker ──────────────────────────────────────────────
            _PickerCard(
              label: 'Height',
              emoji: '📏',
              isInteracted: _heightInteracted,
              preview: _heightPreview(vm),
              child: SizedBox(
                height: 160,
                child: isMetric
                    ? CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: _meterIndex(vm.selectedMeters)),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) {
                          setState(() => _heightInteracted = true);
                          vm.selectHeightMeters(_meterList[i]);
                        },
                        children: _meterList.map((m) => Center(
                          child: Text('${m.toStringAsFixed(1)} m',
                              style: GoogleFonts.poppins(fontSize: 16)))).toList(),
                      )
                    : Row(children: [
                        Expanded(child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                              initialItem: (vm.selectedFeet - 2).clamp(0, _feetList.length - 1)),
                          itemExtent: 40,
                          onSelectedItemChanged: (i) {
                            setState(() => _heightInteracted = true);
                            vm.selectHeightFt(_feetList[i], vm.selectedInches);
                          },
                          children: _feetList.map((f) => Center(
                            child: Text('$f ft', style: GoogleFonts.poppins(fontSize: 16)))).toList(),
                        )),
                        Expanded(child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                              initialItem: vm.selectedInches.clamp(0, _inchList.length - 1)),
                          itemExtent: 40,
                          onSelectedItemChanged: (i) {
                            setState(() => _heightInteracted = true);
                            vm.selectHeightFt(vm.selectedFeet, i);
                          },
                          children: _inchList.map((i) => Center(
                            child: Text('$i in', style: GoogleFonts.poppins(fontSize: 16)))).toList(),
                        )),
                      ]),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

            // ── Weight picker ──────────────────────────────────────────────
            _PickerCard(
              label: 'Weight',
              emoji: '⚖️',
              isInteracted: _weightInteracted,
              preview: _weightPreview(vm),
              child: SizedBox(
                height: 160,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: isMetric
                        ? (vm.selectedKg - 40).clamp(0, _kgList.length - 1)
                        : (vm.selectedLbs - 80).clamp(0, _lbsList.length - 1),
                  ),
                  itemExtent: 40,
                  onSelectedItemChanged: (i) {
                    setState(() => _weightInteracted = true);
                    if (isMetric) {
                      vm.selectWeightValues(kg: _kgList[i]);
                    } else {
                      vm.selectWeightValues(lbs: _lbsList[i]);
                    }
                  },
                  children: (isMetric ? _kgList : _lbsList).map((w) => Center(
                    child: Text('$w ${isMetric ? 'kg' : 'lbs'}',
                        style: GoogleFonts.poppins(fontSize: 16)))).toList(),
                ),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
          ],
          onContinue: () {
            if (!_heightInteracted || !_weightInteracted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select both your height and weight.')),
              );
              return;
            }
            final heightStr = isMetric
                ? '${vm.selectedMeters.toStringAsFixed(1)} m'
                : '${vm.selectedFeet} ft ${vm.selectedInches} in';
            final weightStr = isMetric ? '${vm.selectedKg} kg' : '${vm.selectedLbs} lbs';
            vm.selectHeight(heightStr);
            vm.selectWeight(weightStr);
            vm.nextStep();
          },
        );
      },
    );
  }

  String _heightPreview(OnboardingViewModel vm) {
    if (!_heightInteracted) return '—';
    return vm.isMetric
        ? '${vm.selectedMeters.toStringAsFixed(1)} m'
        : '${vm.selectedFeet} ft ${vm.selectedInches} in';
  }

  String _weightPreview(OnboardingViewModel vm) {
    if (!_weightInteracted) return '—';
    return vm.isMetric ? '${vm.selectedKg} kg' : '${vm.selectedLbs} lbs';
  }

  int _meterIndex(double meters) {
    double minDiff = double.infinity;
    int idx = 0;
    for (int i = 0; i < _meterList.length; i++) {
      final d = (meters - _meterList[i]).abs();
      if (d < minDiff) { minDiff = d; idx = i; }
    }
    return idx;
  }
}

// ── Subwidgets ──────────────────────────────────────────────────────────────

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.isMetric, required this.onToggle});
  final bool isMetric;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(50)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _Tab(label: 'Imperial', active: !isMetric, onTap: () => onToggle(false)),
        _Tab(label: 'Metric',   active: isMetric,  onTap: () => onToggle(true)),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(label, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: active ? _lime : Colors.black54)),
      ),
    );
  }
}

class _PickerCard extends StatelessWidget {
  const _PickerCard({
    required this.label,
    required this.emoji,
    required this.isInteracted,
    required this.preview,
    required this.child,
  });

  final String label, emoji, preview;
  final bool isInteracted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isInteracted ? _lime : Colors.transparent, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
          const Spacer(),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isInteracted ? Colors.black87 : Colors.black26,
            ),
            child: Text(preview),
          ),
        ]),
        const SizedBox(height: 6),
        child,
      ]),
    );
  }
}
