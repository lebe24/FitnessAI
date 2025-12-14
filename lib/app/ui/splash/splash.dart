import 'dart:async';
import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/core/routes/app_router.dart';
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/core/di.dart';
import 'package:fitness/app/ui/auth/domain/usecase/get_current_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitness/app/core/common/widget/appWidget.dart';
import 'package:google_fonts/google_fonts.dart';

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
    // Check authentication and navigate after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _checkAuthenticationAndNavigate();
      }
    });
  }

  void _checkAuthenticationAndNavigate() {
    final user = _getCurrentUser();
    if (user != null) {
      // User is authenticated, navigate to home
      context.go(ScreenPaths.home);
    } else {
      // User is not authenticated, navigate to welcome
      context.go(ScreenPaths.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child:Center(
          child:AppWidgets.appLogo().animate().fadeIn(duration: 2.seconds)
        )
      )
    );
  }
}