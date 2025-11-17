import 'package:fitness/app/core/constant/assets.dart';
import 'package:fitness/app/core/di.dart';
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/core/common/widget/RoundbuttonText.dart';
import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/ui/auth/domain/usecase/get_current_user.dart';
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
                          backgroundColor: AppPallete.accent1,
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
                  child: RoundBtnText(
                    onPressed: () => context.go('/onboarding'),
                    text: "Get Started",
                  ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3, end: 0),
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Check if user is authenticated
                        final getCurrentUser = sl<GetCurrentUser>();
                        final user = getCurrentUser();
                        
                        if (user != null) {
                          // User is authenticated, navigate to home
                          context.go('/home');
                        } else {
                          // User is not authenticated, show message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                "You are not a registered user. Please sign up first.",
                              ),
                              action: SnackBarAction(
                                label: 'Sign Up',
                                textColor: Colors.white,
                                onPressed: () {
                                  context.go('/onboarding');
                                },
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        "Login",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3, end: 0)
              ],
            ),
          )
        ],
      ),
    );
  }
}