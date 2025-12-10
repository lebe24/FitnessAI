import 'package:fitness/app/core/common/widget/appWidget.dart';
import 'package:fitness/app/ui/auth/presentation/bloc/auth_bloc.dart';
import 'package:fitness/app/ui/auth/presentation/bloc/auth_event.dart';
import 'package:fitness/app/ui/auth/presentation/bloc/auth_state.dart';
import 'package:fitness/app/ui/onboarding/bloc/onboarding_bloc.dart';
import 'package:fitness/app/ui/onboarding/presentation/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUp extends StatelessWidget {
  const SignUp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final isAuthenticated = state is AuthAuthenticated;
        final authenticatedUser = state is AuthAuthenticated ? state.user : null;

        return BaseStepLayout(
          title: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              children: const [
                TextSpan(
                  text: "One More Step ",
                ),
                TextSpan(
                  text: "\nSignUp",
                  style: TextStyle(
                    backgroundColor: Color(0xFFCCFF00),
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          subtitle: "This data allows the AI to tailor your workout",
          children: [
            if (isAuthenticated && authenticatedUser != null)
              SizedBox(
                height: 400,
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          "Welcome, ${authenticatedUser.name ?? authenticatedUser.email ?? 'User'}!",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "You have successfully signed up",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 400,
                child: Center(
                  child: isLoading
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              "Signing you up...",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                        width: 250,
                        child: AppWidgets.roundbtnText(
                            onPressed: () {
                              if (isLoading) return;
                              context
                                  .read<AuthBloc>()
                                  .add(SignInWithGoogleRequested());
                            },
                            text: "Sign up with Google",
                          )
                            .animate()
                            .fadeIn(duration: 1200.ms)
                            .slideY(begin: 0.3, end: 0),
                      ),
                ),
              ),
          ],
          onContinue: () {
            // Only proceed to next step if user is authenticated
            if (isAuthenticated && authenticatedUser != null) {
              context.read<OnboardingBloc>().add(NextStep());
            } else {
              // Show error message if user hasn't signed up
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.orange,
                  content: Text(
                    "Please sign up with Google before continuing",
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}