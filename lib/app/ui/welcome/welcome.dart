import 'package:fitness/app/core/constant/assets.dart';
import 'package:fitness/app/core/di.dart';
import 'package:fitness/app/core/common/widget/appWidget.dart';
import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/ui/auth/domain/usecase/get_current_user.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';


class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return  Scaffold(
      body: Stack(
        children: [
          Stack(
            children: [
              // SizedBox(
              //   height: 50,
              //   width: 50,
              //   child: Image.asset(
              //     ImagePath.appLogo,
              //     width: 50,
              //     height: 50,
              //   ),
              // ),
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
                    ImagePath.appBackgroundImage,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: size.height * 0.05,
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
                          TextSpan(text: "Trans"),
                          TextSpan(
                            text: "form",
                            style: TextStyle(
                              backgroundColor: const Color(0xFFCCFF00),
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(text: " Your Body\nWith AI"),
                      ],)
                    ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 12),
                    // Subtitle
                    Text(
                      "Upload your photo, get a personalized workout plan, "
                      "and track your progress with the power of AI.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ).animate(delay: 500.ms).fadeIn(duration: 1000.ms).slideY(begin: 0.2, end: 0),
          
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: AppWidgets.roundbtnText(
                        onPressed: () => context.go('/onboarding'),
                        text: "Get Started",
                      ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3, end: 0),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        children: [
                          TextSpan(text: "Already have an account?"),
                          
                          TextSpan(
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                final getCurrentUser = sl<GetCurrentUser>();
                                final user = getCurrentUser();
          
                                context.go('/login');
                              },
                            style: TextStyle(
                              color: const Color(0xFF418A43),
                              fontWeight: FontWeight.bold,
                            ),
                            text: "\t Login"),
                        ],
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