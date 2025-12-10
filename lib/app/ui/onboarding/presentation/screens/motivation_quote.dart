import 'dart:async';

import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/core/constant/assets.dart';
import 'package:fitness/app/core/common/widget/appWidget.dart';
import 'package:fitness/app/core/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';


class MotivationQuote extends StatefulWidget {
  const MotivationQuote({super.key});

  @override
  State<MotivationQuote> createState() => _MotivationQuoteState();
}

class _MotivationQuoteState extends State<MotivationQuote> {
  @override
  void initState() {
    super.initState();
    // Navigate to welcome screen after 3 seconds
    Timer(const Duration(seconds: 12), () {
      if (mounted) {
        context.go(ScreenPaths.analysis);
      }
    });
  }
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return  Scaffold(
      body: Stack(
        children: [
          Stack(
            children: [
              // Darken the top half of the screen
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF060705),
                        Color(0xC6ABABAB),
                      ],
                      stops: [0.5, 0.5],
                    ),
                  ),
                ),
              ),
              // Show the image starting from the vertical center,
              // fading out as it approaches the bottom text.
              Positioned(
                left: 0,
                right: 0,
                bottom: 300,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF797979),
                        Colors.transparent,
                      ],
                      stops: [0.7, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    ImagePath.beFitbanner,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: size.height * 0.15,
                left: 24,
                right: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                      style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                      ),
                      children:  [
                          TextSpan(text: "Consistency Is The"),
                          TextSpan(
                            text: " \nKey",
                            style: TextStyle(
                              backgroundColor: const Color(0xFFCCFF00),
                              color: Colors.black,
                            ),
                          ),
                          // TextSpan(text: " To Achieve your Dream\nBody"),
                      ],)
                    ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 12),
                    // Subtitle
                    Text(
                      "BEFIT gives you the power to leverage AI to create workout plan tailored to your needs to achieve your dream body.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3, end: 0),
                    
                  ],
                ),
              ),
              
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: AppWidgets.appLogo(),
          )
        ],
      ),
    );
  }
}