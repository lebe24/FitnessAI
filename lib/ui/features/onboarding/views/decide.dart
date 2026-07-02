import 'package:fitness/ui/core/di.dart' as di;
import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _lime = Color(0xFFCCFF00);

class DecideStep extends StatelessWidget {
  const DecideStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<OnboardingViewModel>();
    final user = di.sl<GetCurrentUser>()();
    final userName = user?.name ?? user?.email ?? 'Athlete';
    final userId = user?.id ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Back button — identical to BaseStepLayout
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => vm.previousStep(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Title
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  children: const [
                    TextSpan(text: "Choose Your\n"),
                    TextSpan(
                      text: 'Path',
                      style: TextStyle(backgroundColor: _lime, color: Colors.black),
                    ),
                    TextSpan(text: '!'),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'How would you like to generate your personalised workout plan?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // Cards
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _DecideCard(
                          icon: Icons.camera_alt_rounded,
                          label: 'Analyse a Photo',
                          description:
                              'Scan your physique and let the AI craft a visual-based workout plan',
                          delay: 70,
                          onTap: () => context.push('/onboarding-analysis'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Progress bar — identical to BaseStepLayout
              const SizedBox(
                height: 6,
                width: double.infinity,
                child: LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: Colors.black12,
                  color: Colors.lightGreen,
                ),
              ),

              const SizedBox(height: 16),

              // Footer hint in place of the Continue button
              Text(
                'Tap a card to get started',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black38,
                  fontWeight: FontWeight.w500,
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Decision card  —  mirrors _GoalCard / _GenderCard exactly
// ─────────────────────────────────────────────────────────────────────────────

class _DecideCard extends StatefulWidget {
  const _DecideCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    required this.delay,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final int delay;

  @override
  State<_DecideCard> createState() => _DecideCardState();
}

class _DecideCardState extends State<_DecideCard> {
  bool _selected = false;

  Future<void> _handleTap() async {
    setState(() => _selected = true);
    await Future.delayed(const Duration(milliseconds: 200));
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _selected ? null : _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: _selected ? Colors.black : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selected ? _lime : Colors.transparent,
            width: 2,
          ),
          boxShadow: _selected
              ? [BoxShadow(
                  color: _lime.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )]
              : [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )],
        ),
        child: Row(children: [
          // Icon circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selected
                  ? _lime.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            child: Icon(
              widget.icon,
              size: 26,
              color: _selected ? _lime : Colors.black87,
            ),
          ),

          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _selected ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _selected
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black45,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Check / arrow indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selected ? _lime : Colors.transparent,
              border: Border.all(
                color: _selected ? _lime : Colors.black.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: _selected
                ? const Icon(Icons.check_rounded, size: 15, color: Colors.black)
                : const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Colors.black38),
          ),
        ]),
      )
          .animate(delay: Duration(milliseconds: widget.delay))
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
    );
  }
}
