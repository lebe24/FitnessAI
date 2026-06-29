import 'package:fitness/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:fitness/ui/features/onboarding/views/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _lime = Color(0xFFCCFF00);

const _levels = [
  ('Beginner',          1, 'Just starting out — no experience needed'),
  ('Experienced',       2, 'Training consistently for 1–3 years'),
  ('Freak of Nature',   3, 'Elite athlete — pushing every limit'),
  ('God in Human Form', 4, 'Legendary status — you ARE the standard'),
];

class ExperienceStep extends StatelessWidget {
  const ExperienceStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (context, vm, _) {
        final selected = vm.data.experience;
        return BaseStepLayout(
          title: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              children: const [
                TextSpan(text: "What's Your\n"),
                TextSpan(text: 'Experience', style: TextStyle(backgroundColor: _lime, color: Colors.black)),
                TextSpan(text: ' Level?'),
              ],
            ),
          ),
          subtitle: 'We calibrate intensity and progression to match you',
          children: [
            for (int i = 0; i < _levels.length; i++)
              _LevelCard(
                label: _levels[i].$1,
                filledBars: _levels[i].$2,
                description: _levels[i].$3,
                isSelected: selected == _levels[i].$1,
                onTap: () => vm.selectExperience(_levels[i].$1),
                delay: i * 70,
              ),
          ],
          onContinue: () {
            if (selected == null || selected.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select your experience level before continuing.')),
              );
              return;
            }
            vm.nextStep();
          },
        );
      },
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.label,
    required this.filledBars,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.delay,
  });

  final String label, description;
  final int filledBars; // 1–4 out of 4
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _lime : Colors.transparent, width: 2),
          boxShadow: isSelected
              ? [BoxShadow(color: _lime.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Level bars
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: List.generate(4, (i) {
              final active = i < filledBars;
              return Container(
                margin: const EdgeInsets.only(right: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? (isSelected ? _lime : Colors.black)
                      : (isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15)),
                ),
              );
            })),
          ]),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.black87)),
            const SizedBox(height: 3),
            Text(description, style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected ? Colors.white.withValues(alpha: 0.6) : Colors.black45,
                height: 1.4)),
          ])),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? _lime : Colors.transparent,
              border: Border.all(
                  color: isSelected ? _lime : Colors.black.withValues(alpha: 0.2), width: 2),
            ),
            child: isSelected ? const Icon(Icons.check_rounded, size: 15, color: Colors.black) : null,
          ),
        ]),
      ).animate(delay: Duration(milliseconds: delay))
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
    );
  }
}
