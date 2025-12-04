import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/core/di.dart' as di;
import 'package:fitness/app/core/routes/app_router.dart';
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/auth/presentation/bloc/auth_event.dart';
import 'package:fitness/app/ui/auth/presentation/bloc/auth_state.dart';
import 'package:fitness/app/ui/onboarding/utils/onboarding_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shows a confirmation dialog for deleting the user account
void showDeleteAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: AppPallete.borderColor.withOpacity(0.9),
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppPallete.whiteColor,
          ),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently deleted.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppPallete.whiteColor.withOpacity(0.9),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppPallete.whiteColor.withOpacity(0.7),
              ),
            ),
          ),
          BlocProvider.value(
            value: di.sl<AuthBloc>(),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthUnauthenticated) {
                  // Clear onboarding data
                  OnboardingStorage.clearOnboardingData();
                  // Navigate to welcome screen
                  Navigator.of(dialogContext).pop();
                  context.go(ScreenPaths.welcome);
                } else if (state is AuthFailure) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppPallete.errorColor,
                      content: Text(
                        'Failed to delete account: ${state.message}',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          context.read<AuthBloc>().add(DeleteAccountRequested());
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppPallete.errorColor,
                          ),
                        )
                      : Text(
                          'Delete',
                          style: GoogleFonts.poppins(
                            color: AppPallete.errorColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

/// Handles user logout with confirmation dialog
void handleLogout(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: AppPallete.borderColor.withOpacity(0.9),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppPallete.whiteColor,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppPallete.whiteColor.withOpacity(0.9),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppPallete.whiteColor.withOpacity(0.7),
              ),
            ),
          ),
          BlocProvider.value(
            value: di.sl<AuthBloc>(),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthUnauthenticated) {
                  // Navigate to welcome screen
                  Navigator.of(dialogContext).pop();
                  context.go(ScreenPaths.welcome);
                } else if (state is AuthFailure) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppPallete.errorColor,
                      content: Text(
                        'Failed to logout: ${state.message}',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          context.read<AuthBloc>().add(SignOutRequested());
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppPallete.whiteColor,
                          ),
                        )
                      : Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            color: AppPallete.whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

