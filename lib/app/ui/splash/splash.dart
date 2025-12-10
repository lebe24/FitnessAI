import 'dart:async';
import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/core/routes/app_router.dart';
import 'package:fitness/app/core/theme/app_pallet.dart';
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
  @override
  void initState() {
    super.initState();
    // Navigate to welcome screen after 3 seconds
    Timer(const Duration(seconds: 8), () {
      if (mounted) {
        context.go(ScreenPaths.welcome);
      }
    });
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