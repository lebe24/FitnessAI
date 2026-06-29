import 'dart:async';
import 'package:fitness/ui/core/routes/app_router.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/ui/features/onboarding/views/onboarding_storage.dart';
import 'package:fitness/ui/core/widgets/app_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final GetCurrentUser _getCurrentUser = sl<GetCurrentUser>();

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) _navigate();
    });
  }

  Future<void> _navigate() async {
    final user = _getCurrentUser();

    if (user != null) {
      // Authenticated → always go home
      context.go(ScreenPaths.home);
      return;
    }

    // Not authenticated — check onboarding state
    final completed = await OnboardingStorage.hasCompletedOnboarding();
    if (!mounted) return;

    if (completed) {
      // User finished onboarding but hasn't signed up/in yet
      context.go(ScreenPaths.analysis);
    } else {
      context.go(ScreenPaths.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AppWidgets.appLogo().animate().fadeIn(duration: 2.seconds),
      ),
    );
  }
}
