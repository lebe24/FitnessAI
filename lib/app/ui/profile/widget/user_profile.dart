// User Profile Section Widget
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/profile/presentation/bloc/profile_bloc.dart';
import 'package:fitness/app/ui/profile/presentation/bloc/profile_event.dart';
import 'package:fitness/app/ui/profile/presentation/bloc/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfileSection extends StatelessWidget {
  const UserProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded) {
          final profile = state.profile;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalete.borderColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppPalete.borderColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A9A8F), // Teal color
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      profile.initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Name and Age
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name ?? profile.email ?? 'User',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppPalete.whiteColor,
                        ),
                      ),
                      if (profile.ageString.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          profile.ageString,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: AppPalete.whiteColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        } else if (state is ProfileLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalete.borderColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppPalete.borderColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppPalete.whiteColor,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Loading profile...',
                    style: TextStyle(
                      color: AppPalete.whiteColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (state is ProfileError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalete.borderColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppPalete.borderColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppPalete.errorColor,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Error loading profile',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppPalete.whiteColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: AppPalete.whiteColor,
                  ),
                  onPressed: () {
                    context.read<ProfileBloc>().add(RefreshProfileEvent());
                  },
                ),
              ],
            ),
          );
        } else {
          // Initial state - show loading placeholder
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalete.borderColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppPalete.borderColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppPalete.whiteColor,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Loading...',
                    style: TextStyle(
                      color: AppPalete.whiteColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
