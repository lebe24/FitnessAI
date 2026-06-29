import 'package:fitness/ui/core/theme/app_pallet.dart';
import 'package:fitness/ui/features/profile/view_models/profile_view_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class UserProfileSection extends StatelessWidget {
  const UserProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading || vm.profile == null) {
          return _shell(child: const Row(children: [
            SizedBox(width: 60, height: 60, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalete.whiteColor)),
            SizedBox(width: 16),
            Expanded(child: Text('Loading...', style: TextStyle(color: AppPalete.whiteColor, fontSize: 16))),
          ]));
        }
        if (vm.error != null) {
          return _shell(child: Row(children: [
            const Icon(Icons.error_outline, color: AppPalete.errorColor, size: 24),
            const SizedBox(width: 16),
            Expanded(child: Text('Error loading profile', style: GoogleFonts.poppins(fontSize: 14, color: AppPalete.whiteColor))),
            IconButton(icon: const Icon(Icons.refresh, color: AppPalete.whiteColor), onPressed: () => vm.refresh()),
          ]));
        }
        final profile = vm.profile!;
        return _shell(child: Row(children: [
          Container(
            width: 60, height: 60,
            decoration: const BoxDecoration(color: Color(0xFF1A9A8F), shape: BoxShape.circle),
            child: Center(child: Text(profile.initial,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(profile.name ?? profile.email ?? 'User',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalete.whiteColor)),
            if (profile.ageString.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(profile.ageString,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppPalete.whiteColor.withOpacity(0.7))),
            ],
          ])),
        ]));
      },
    );
  }

  Widget _shell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalete.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalete.borderColor.withOpacity(0.2)),
      ),
      child: child,
    );
  }
}
