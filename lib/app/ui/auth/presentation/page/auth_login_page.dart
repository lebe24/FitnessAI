import 'package:fitness/app/core/common/widget/appWidget.dart';
import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/core/di.dart';
import 'package:fitness/app/ui/auth/presentation/bloc/auth_bloc.dart';
import 'package:fitness/app/ui/auth/presentation/bloc/auth_event.dart';
import 'package:fitness/app/ui/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class AuthLoginPage extends StatefulWidget {
  const AuthLoginPage({super.key});

  @override
  State<AuthLoginPage> createState() => _AuthLoginPageState();
}

class _AuthLoginPageState extends State<AuthLoginPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthBloc>(),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.redAccent,
                content: Text(state.message),
              ),
            );
          }
          if (state is AuthAuthenticated) {
            // Navigate to home when authenticated
            context.go('/home');
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final isAuthenticated = state is AuthAuthenticated;
          final authenticatedUser = state is AuthAuthenticated ? state.user : null;

          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Title
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          children: [
                            const TextSpan(
                              text: "Welcome ",
                            ),
                            const TextSpan(
                              text: "Back",
                              style: TextStyle(
                                backgroundColor: Color(0xFFCCFF00),
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        "Enter your Gmail address to continue",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      // Content area
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
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
                                            "Welcome back, ${authenticatedUser.name ?? authenticatedUser.email ?? 'User'}!",
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          "You have successfully logged in",
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
                                                "Verifying Gmail...",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          )
                                        : SizedBox(
                                            width: double.infinity,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                TextFormField(
                                                  controller: _emailController,
                                                  keyboardType: TextInputType.emailAddress,
                                                  decoration: InputDecoration(
                                                    labelText: "Gmail Address",
                                                    hintText: "example@gmail.com",
                                                    prefixIcon: const Icon(Icons.email_outlined),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      borderSide: BorderSide(
                                                        color: Colors.grey[300]!,
                                                      ),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      borderSide: const BorderSide(
                                                        color: Color(0xFF418A43),
                                                        width: 2,
                                                      ),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                      horizontal: 16,
                                                    ),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) {
                                                      return 'Please enter your Gmail address';
                                                    }
                                                    final email = value.toLowerCase().trim();
                                                    if (!email.endsWith('@gmail.com')) {
                                                      return 'Please enter a valid Gmail address';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 24),
                                                SizedBox(
                                                  width:double.infinity,
                                                  child: AppWidgets.roundbtnText(
                                                    onPressed: () {
                                                      if (_formKey.currentState!.validate()) {
                                                        context.read<AuthBloc>().add(
                                                              SignInWithGmailRequested(_emailController.text),
                                                            );
                                                      }
                                                    },
                                                    text: "Continue with Gmail",
                                                  ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Continue button (only show when authenticated)
                      if (isAuthenticated && authenticatedUser != null)
                        SizedBox(
                          width: double.infinity,
                          child: AppWidgets.roundbtnText(
                            onPressed: () {
                              context.go('/home');
                            },
                            text: "Continue",
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

