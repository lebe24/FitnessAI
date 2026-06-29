import 'package:fitness/ui/core/constants/assets.dart';
import 'package:fitness/ui/features/auth/view_models/auth_view_model.dart';
import 'package:fitness/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:fitness/ui/features/onboarding/views/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _lime = Color(0xFFCCFF00);

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  late final AuthViewModel _authVm;

  @override
  void initState() {
    super.initState();
    _authVm = context.read<AuthViewModel>();
    _authVm.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (!mounted) return;
    if (_authVm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(_authVm.error!),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _authVm.clearError();
    }
  }

  @override
  void dispose() {
    _authVm.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVm, _) {
        final onboardingVm = context.read<OnboardingViewModel>();

        return BaseStepLayout(
          title: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              children: const [
                TextSpan(text: 'Almost '),
                TextSpan(
                  text: 'There',
                  style: TextStyle(backgroundColor: _lime, color: Colors.black),
                ),
                TextSpan(text: '!'),
              ],
            ),
          ),
          subtitle: 'Create your account to save your plan and track progress',
          children: authVm.isAuthenticated && authVm.user != null
              ? [_SuccessState(user: authVm.user!)]
              : [
                  // ── Perks card ─────────────────────────────────────────
                  _PerksCard()
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

                  // ── Google button ──────────────────────────────────────
                  authVm.isLoading
                      ? _LoadingCard()
                      : _GoogleSignInButton(
                          onTap: () => authVm.signInWithGoogle(),
                        ).animate(delay: 120.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                ],
          onContinue: () {
            if (authVm.isAuthenticated && authVm.user != null) {
              onboardingVm.nextStep();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.orange.shade800,
                  content: Text(
                    'Sign up with Google to continue',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
        );
      },
    );
  }
}

// ── Perks card ───────────────────────────────────────────────────────────────

class _PerksCard extends StatelessWidget {
  const _PerksCard();

  @override
  Widget build(BuildContext context) {
    const perks = [
      (Icons.bolt_rounded,       'AI Workout Plans',    'Personalised to your body and goals'),
      (Icons.restaurant_rounded,  'Nutrition Tracking',  'Scan food and hit your macros daily'),
      (Icons.trending_up_rounded, 'Progress Insights',   'Track streaks, strength and body changes'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _lime.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What you're unlocking",
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          for (final p in perks) ...[
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _lime.withValues(alpha: 0.12),
                ),
                child: Icon(p.$1, size: 20, color: _lime),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.$2, style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                  Text(p.$3, style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.white54)),
                ],
              )),
              const Icon(Icons.check_circle_rounded, size: 18, color: _lime),
            ]),
            if (p != perks.last) const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white10, height: 1),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Google sign-in button ─────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" logo drawn with text (no asset needed)
            Container(
              width: 24, height: 24,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Image.asset(
                ImagePath.googleLogo,
                width: 24, height: 24,
                errorBuilder: (_, __, ___) => const Text('G',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: Color(0xFF4285F4))),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading card ──────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black87),
        ),
        const SizedBox(width: 14),
        Text('Signing you in…', style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
      ]),
    );
  }
}

// ── Success state ─────────────────────────────────────────────────────────────

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final name = (user.name as String?)?.split(' ').first ?? user.email ?? 'Athlete';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _lime, width: 2),
        boxShadow: [
          BoxShadow(
              color: _lime.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(children: [
        // Animated check
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _lime.withValues(alpha: 0.15),
            border: Border.all(color: _lime, width: 2),
          ),
          child: const Icon(Icons.check_rounded, color: _lime, size: 36),
        ).animate().scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.0, 1.0),
            curve: Curves.elasticOut,
            duration: 700.ms),
        const SizedBox(height: 16),
        Text(
          "Welcome, $name! 👋",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 6),
        Text(
          "Your account is ready.\nTap Continue to generate your plan.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 13, color: Colors.white54, height: 1.5),
        ).animate().fadeIn(delay: 450.ms),
      ]),
    );
  }
}
