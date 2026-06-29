import 'package:fitness/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:fitness/ui/features/onboarding/views/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _lime = Color(0xFFCCFF00);

class WorkoutDaysStep extends StatelessWidget {
  const WorkoutDaysStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (context, vm, _) {
        final selected = vm.data.workoutDays;
        return BaseStepLayout(
          title: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              children: const [
                TextSpan(text: 'How Many Days\nDo You '),
                TextSpan(
                  text: 'Train',
                  style: TextStyle(
                    backgroundColor: _lime,
                    color: Colors.black,
                  ),
                ),
                TextSpan(text: ' Per Week?'),
              ],
            ),
          ),
          subtitle: 'This helps the AI build your perfect plan',
          children: [
            _DayCard(
              days: 2,
              range: '1 – 2',
              label: 'Hobbyist',
              description: 'Stay active and build healthy habits',
              activeDots: 2,
              isSelected: selected == 2,
              onTap: () => vm.selectWorkoutDays(2),
              delay: 0,
            ),
            _DayCard(
              days: 4,
              range: '3 – 4',
              label: 'Fitness Guru',
              description: 'Build serious gains with balanced recovery',
              activeDots: 4,
              isSelected: selected == 4,
              onTap: () => vm.selectWorkoutDays(4),
              delay: 80,
            ),
            _DayCard(
              days: 6,
              range: '6 +',
              label: 'Athlete',
              description: 'Elite training for maximum performance',
              activeDots: 6,
              isSelected: selected == 6,
              onTap: () => vm.selectWorkoutDays(6),
              delay: 160,
            ),
          ],
          onContinue: () {
            if (selected == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Please select how many days you train per week.'),
              ));
              return;
            }
            vm.nextStep();
          },
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.days,
    required this.range,
    required this.label,
    required this.description,
    required this.activeDots,
    required this.isSelected,
    required this.onTap,
    required this.delay,
  });

  final int days;
  final String range;
  final String label;
  final String description;
  final int activeDots;
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
          border: Border.all(
            color: isSelected ? _lime : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: _lime.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // ── Left: range + dots ────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  range,
                  style: GoogleFonts.poppins(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? _lime : Colors.black,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(7, (i) {
                    final active = i < activeDots;
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? (isSelected ? _lime : Colors.black)
                            : (isSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.15)),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // ── Right: label + description ────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Checkmark ─────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _lime : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _lime : Colors.black.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.black)
                  : null,
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: delay))
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
    );
  }
}
