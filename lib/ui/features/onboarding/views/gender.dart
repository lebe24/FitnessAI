import 'package:fitness/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:fitness/ui/features/onboarding/views/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _lime = Color(0xFFCCFF00);

class GenderStep extends StatelessWidget {
  const GenderStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (context, vm, _) {
        final selected = vm.data.gender;
        return BaseStepLayout(
          title: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              children: const [
                TextSpan(text: 'What Is Your\n'),
                TextSpan(text: 'Gender', style: TextStyle(backgroundColor: _lime, color: Colors.black)),
                TextSpan(text: '?'),
              ],
            ),
          ),
          subtitle: 'This helps us personalise your training program',
          children: [
            _GenderCard(
              value: 'Male',
              icon: Icons.male_rounded,
              description: 'Optimised for male physiology & hormones',
              isSelected: selected == 'Male',
              onTap: () => vm.selectGender('Male'),
              delay: 0,
            ),
            _GenderCard(
              value: 'Female',
              icon: Icons.female_rounded,
              description: 'Tuned for female physiology & cycle phases',
              isSelected: selected == 'Female',
              onTap: () => vm.selectGender('Female'),
              delay: 80,
            ),
            _GenderCard(
              value: 'Non-binary',
              icon: Icons.transgender_rounded,
              description: 'Neutral plan built around your own goals',
              isSelected: selected == 'Non-binary',
              onTap: () => vm.selectGender('Non-binary'),
              delay: 160,
            ),
          ],
          onContinue: () {
            if (selected == null || selected.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a gender before continuing.')),
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

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.value,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.delay,
  });

  final String value;
  final IconData icon;
  final String description;
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _lime : Colors.transparent, width: 2),
          boxShadow: isSelected
              ? [BoxShadow(color: _lime.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Icon circle
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? _lime.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.06),
            ),
            child: Icon(icon, size: 28, color: isSelected ? _lime : Colors.black87),
          ),
          const SizedBox(width: 16),
          // Text
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.black87)),
            const SizedBox(height: 3),
            Text(description, style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected ? Colors.white.withValues(alpha: 0.6) : Colors.black45,
                height: 1.4)),
          ])),
          const SizedBox(width: 12),
          // Check circle
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
