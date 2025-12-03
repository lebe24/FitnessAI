import 'dart:async';
import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/core/routes/app_router.dart';
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        context.go(ScreenPaths.welcome);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [

              AppPallete.gradient3, // Purple
              AppPallete.gradient2, // Pink
              AppPallete.gradient3, // Orange
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon/Logo placeholder - you can replace this with your app icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppPallete.whiteColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppPallete.whiteColor.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.fitness_center,
                  size: 60,
                  color: AppPallete.whiteColor,
                ),
              )
                  .animate()
                  .scale(
                    duration: 800.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: 600.ms),
              
              const SizedBox(height: 40),
              
              // App Name
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.whiteColor,
                    letterSpacing: 1.2,
                  ),
                  children: [
                    TextSpan(text: "Trans"),
                    TextSpan(
                      text: "form",
                      style: TextStyle(
                        backgroundColor: AppPallete.accent1,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(text: "\nYour Body With AI"),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: 1000.ms,
                    delay: 300.ms,
                  )
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    duration: 1000.ms,
                    delay: 300.ms,
                    curve: Curves.easeOut,
                  ),
              
              const SizedBox(height: 60),
              
              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppPallete.whiteColor.withOpacity(0.8),
                  ),
                  strokeWidth: 3,
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: 800.ms,
                    delay: 1200.ms,
                  )
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 800.ms,
                    delay: 1200.ms,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}