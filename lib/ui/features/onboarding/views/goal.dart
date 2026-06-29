import 'package:fitness/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:fitness/ui/features/onboarding/views/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _lime = Color(0xFFCCFF00);

const _presets = [
  ('Lose Weight',      '🔥', 'Burn fat, reveal your shape'),
  ('Build Muscle',     '💪', 'Add size, strength and definition'),
  ('Maintain Gains',   '⚖️', 'Keep what you have and stay lean'),
  ('Build Aesthetics', '🎨', 'Sculpt a symmetrical, visual physique'),
];

bool _isPreset(String? value) => _presets.any((p) => p.$1 == value);

class GoalStep extends StatefulWidget {
  const GoalStep({super.key});

  @override
  State<GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends State<GoalStep> {
  late final TextEditingController _controller;
  bool _fieldActive = false;

  @override
  void initState() {
    super.initState();
    final existing = context.read<OnboardingViewModel>().data.goal;
    final initialText = _isPreset(existing) ? '' : (existing ?? '');
    _controller = TextEditingController(text: initialText);
    _fieldActive = initialText.isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPresetTap(OnboardingViewModel vm, String preset) {
    // Clear custom field when a preset is chosen
    _controller.clear();
    setState(() => _fieldActive = false);
    vm.selectGoal(preset);
  }

  void _onCustomChanged(OnboardingViewModel vm, String value) {
    setState(() => _fieldActive = value.trim().isNotEmpty);
    if (value.trim().isNotEmpty) {
      vm.selectGoal(value.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (context, vm, _) {
        final selected = vm.data.goal;

        return BaseStepLayout(
          title: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              children: const [
                TextSpan(text: "What's Your\n"),
                TextSpan(
                    text: 'Goal',
                    style: TextStyle(backgroundColor: _lime, color: Colors.black)),
                TextSpan(text: '?'),
              ],
            ),
          ),
          subtitle: 'Your AI plan is built entirely around this',
          children: [
            // Preset cards
            for (int i = 0; i < _presets.length; i++)
              _GoalCard(
                label: _presets[i].$1,
                emoji: _presets[i].$2,
                description: _presets[i].$3,
                isSelected: !_fieldActive && selected == _presets[i].$1,
                onTap: () => _onPresetTap(vm, _presets[i].$1),
                delay: i * 70,
              ),

            // Custom text field — always a StatefulWidget, controller never rebuilt
            _CustomGoalField(
              controller: _controller,
              isActive: _fieldActive,
              onChanged: (v) => _onCustomChanged(vm, v),
            ).animate(delay: 280.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
          ],
          onContinue: () {
            final goal = _fieldActive
                ? _controller.text.trim()
                : selected;
            if (goal == null || goal.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Please choose or enter a goal before continuing.')),
              );
              return;
            }
            // Ensure VM has the latest custom value before navigating
            if (_fieldActive) vm.selectGoal(goal);
            vm.nextStep();
          },
        );
      },
    );
  }
}

// ── Preset card ──────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.label,
    required this.emoji,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.delay,
  });

  final String label, emoji, description;
  final bool isSelected;
  final VoidCallback onTap;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? _lime : Colors.transparent, width: 2),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: _lime.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6))]
              : [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? _lime.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(
                  fontSize: 22,
                  inherit: false,
                  fontFamilyFallback: [
                    'Apple Color Emoji', // iOS/macOS (correct name with spaces)
                    'Noto Color Emoji',  // Android
                    'Segoe UI Emoji',    // Windows
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.black87)),
              const SizedBox(height: 2),
              Text(description, style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black45)),
            ],
          )),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? _lime : Colors.transparent,
              border: Border.all(
                  color: isSelected ? _lime : Colors.black.withValues(alpha: 0.2),
                  width: 2),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, size: 15, color: Colors.black)
                : null,
          ),
        ]),
      )
          .animate(delay: Duration(milliseconds: delay))
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
    );
  }
}

// ── Custom text field ────────────────────────────────────────────────────────

class _CustomGoalField extends StatelessWidget {
  const _CustomGoalField({
    required this.controller,
    required this.isActive,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isActive;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.black : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isActive ? _lime : Colors.transparent, width: 2),
        boxShadow: isActive
            ? [BoxShadow(
                color: _lime.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6))]
            : [],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? _lime.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.06),
          ),
          child: Center(
            child: Text(
              '✏️',
              style: const TextStyle(
                fontSize: 20,
                inherit: false,
                fontFamilyFallback: [
                  'Apple Color Emoji',
                  'Noto Color Emoji',
                  'Segoe UI Emoji',
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 1,
            textInputAction: TextInputAction.done,
            style: GoogleFonts.poppins(
                fontSize: 15,
                color: isActive ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Something else? Type it here…',
              hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black38),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        // Clear button when active
        if (isActive)
          GestureDetector(
            onTap: () {
              controller.clear();
              onChanged('');
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.close_rounded, size: 18, color: Colors.white54),
            ),
          ),
      ]),
    );
  }
}
