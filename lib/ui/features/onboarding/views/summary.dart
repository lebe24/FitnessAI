import 'package:fitness/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:fitness/ui/features/onboarding/views/share_screen.dart';
import 'package:fitness/ui/features/onboarding/views/onboarding_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _lime = Color(0xFFCCFF00);

class SummaryStep extends StatelessWidget {
  const SummaryStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (context, vm, _) {
        final d = vm.data;
        final items = [
          ('👤', 'Gender',    d.gender      ?? '—'),
          ('🎯', 'Goal',      d.goal        ?? '—'),
          ('📅', 'Days/week', '${d.workoutDays ?? '—'} days'),
          ('🏋️', 'Experience', d.experience  ?? '—'),
          ('📏', 'Height',    d.height      ?? '—'),
          ('⚖️', 'Weight',    d.weight      ?? '—'),
          ('🎂', 'Date of Birth', d.dob     ?? '—'),
        ];

        return BaseStepLayout(
          title: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              children: const [
                TextSpan(text: 'Your '),
                TextSpan(text: 'Summary', style: TextStyle(backgroundColor: _lime, color: Colors.black)),
              ],
            ),
          ),
          subtitle: "Here's what we'll use to build your plan",
          children: [
            for (int i = 0; i < items.length; i++)
              _SummaryRow(
                emoji: items[i].$1,
                label: items[i].$2,
                value: items[i].$3,
                delay: i * 60,
              ),
          ],
          onContinue: () async {
            await OnboardingStorage.saveOnboardingData(d);
            vm.nextStep();
          },
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.emoji,
    required this.label,
    required this.value,
    required this.delay,
  });

  final String emoji, label, value;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: GoogleFonts.poppins(
            fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500))),
        Text(value, style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
      ]),
    ).animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}
