import 'package:fitness/ui/core/di.dart' as di;
import 'package:fitness/ui/core/theme/app_pallet.dart';
import 'package:fitness/ui/features/auth/view_models/auth_view_model.dart';
import 'package:fitness/ui/features/onboarding/views/onboarding_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void showDeleteAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return ChangeNotifierProvider(
        create: (_) => di.sl<AuthViewModel>(),
        child: Builder(builder: (innerCtx) {
          final vm = innerCtx.watch<AuthViewModel>();
          if (vm.user == null && !vm.isLoading && vm.error == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              OnboardingStorage.clearOnboardingData();
              context.go('/welcome');
            });
          }
          if (vm.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: AppPalete.errorColor,
                content: Text('Failed to delete account: ${vm.error}', style: GoogleFonts.poppins()),
              ));
              vm.clearError();
            });
          }
          return AlertDialog(
            backgroundColor: AppPalete.borderColor.withOpacity(0.9),
            title: Text('Delete Account',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppPalete.whiteColor)),
            content: Text(
                'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently deleted.',
                style: GoogleFonts.poppins(fontSize: 14, color: AppPalete.whiteColor.withOpacity(0.9))),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancel', style: GoogleFonts.poppins(color: AppPalete.whiteColor.withOpacity(0.7))),
              ),
              TextButton(
                onPressed: vm.isLoading ? null : () => vm.deleteAccount(),
                child: vm.isLoading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppPalete.errorColor))
                    : Text('Delete',
                        style: GoogleFonts.poppins(color: AppPalete.errorColor, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }),
      );
    },
  );
}

void handleLogout(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return ChangeNotifierProvider(
        create: (_) => di.sl<AuthViewModel>(),
        child: Builder(builder: (innerCtx) {
          final vm = innerCtx.watch<AuthViewModel>();
          if (vm.user == null && !vm.isLoading && vm.error == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              context.go('/welcome');
            });
          }
          if (vm.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: AppPalete.errorColor,
                content: Text('Failed to logout: ${vm.error}', style: GoogleFonts.poppins()),
              ));
              vm.clearError();
            });
          }
          return AlertDialog(
            backgroundColor: AppPalete.borderColor.withOpacity(0.9),
            title: Text('Logout',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppPalete.whiteColor)),
            content: Text('Are you sure you want to logout?',
                style: GoogleFonts.poppins(fontSize: 14, color: AppPalete.whiteColor.withOpacity(0.9))),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancel', style: GoogleFonts.poppins(color: AppPalete.whiteColor.withOpacity(0.7))),
              ),
              TextButton(
                onPressed: vm.isLoading ? null : () => vm.signOut(),
                child: vm.isLoading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppPalete.whiteColor))
                    : Text('Logout',
                        style: GoogleFonts.poppins(color: AppPalete.whiteColor, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }),
      );
    },
  );
}
