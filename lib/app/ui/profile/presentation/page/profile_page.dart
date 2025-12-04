import 'package:fitness/app/core/di.dart' as di;
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/profile/presentation/bloc/profile_bloc.dart';
import 'package:fitness/app/ui/profile/presentation/bloc/profile_event.dart';
import 'package:fitness/app/ui/profile/presentation/page/personal_details.dart';
import 'package:fitness/app/ui/profile/utils/profile_dialogs.dart';
import 'package:fitness/app/ui/profile/widget/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ProfileBloc>()..add(LoadProfileEvent()),
      child: Scaffold(
        backgroundColor: AppPallete.backgroundColorBk,
        body: SafeArea(
          child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Text(
                  'Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.whiteColor,
                  ),
                ),
              ),
            ),

            // User Profile Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: const UserProfileSection(),
              ),
            ),

            // Invite Friends Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _InviteFriendsSection(),
              ),
            ),

            // General Settings
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _SettingsSection(
                  title: 'General',
                  items: _generalSettingsItems,
                ),
              ),
            ),

            // Legal & Support
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _SettingsSection(
                  title: 'Legal & Support',
                  items: _legalSupportItems,
                ),
              ),
            ),

            // Account Management
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _SettingsSection(
                  title: 'Account',
                  items: _accountItems,
                ),
              ),
            ),

            // Version Information
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'VERSION 1.0.177',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppPallete.whiteColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
      ),
    );
  }
}



// Invite Friends Section Widget
class _InviteFriendsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPallete.borderColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.people_outline,
                color: AppPallete.whiteColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Invite friends',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.whiteColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Image placeholder (you can replace with actual image)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppPallete.borderColor.withOpacity(0.5),
                  AppPallete.borderColor.withOpacity(0.3),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Placeholder for image
                Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: AppPallete.whiteColor.withOpacity(0.3),
                    size: 48,
                  ),
                ),
                // Overlay text
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The journey',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.whiteColor,
                        ),
                      ),
                      Text(
                        'is easier together.',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.whiteColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Referral Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement referral functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.whiteColor,
                foregroundColor: AppPallete.backgroundColorBk,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
      child: Text(
                'Refer a friend to earn \$10',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Settings Section Widget
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPallete.borderColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title (optional, can be removed if not needed)
          // Text(
          //   title,
          //   style: GoogleFonts.poppins(
          //     fontSize: 14,
          //     fontWeight: FontWeight.w600,
          //     color: AppPallete.whiteColor.withOpacity(0.7),
          //   ),
          // ),
          // const SizedBox(height: 12),
          // Settings items
          ...items.map((item) => _SettingsListItem(
                icon: item.icon,
                title: item.title,
                onTap: item.onTap,
                isLast: items.last == item,
              )),
        ],
      ),
    );
  }
}

// Settings List Item Widget
class _SettingsListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Function(BuildContext)? onTap;
  final bool isLast;

  const _SettingsListItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap != null ? () => onTap!(context) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppPallete.whiteColor,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppPallete.whiteColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppPallete.whiteColor.withOpacity(0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: AppPallete.whiteColor.withOpacity(0.1),
          ),
      ],
    );
  }
}

// Settings Item Model
class _SettingsItem {
  final IconData icon;
  final String title;
  final Function(BuildContext)? onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    this.onTap,
  });
}

// General Settings Items
final List<_SettingsItem> _generalSettingsItems = [
  _SettingsItem(
    icon: Icons.person_outline,
    title: 'Personal details',
    onTap: (context) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PersonalDetailsPage(),
        ),
      );
    },
  ),
  _SettingsItem(
    icon: Icons.refresh,
    title: 'Adjust workout level',
    onTap: (context) {
      // TODO: Navigate to macronutrients page
    },
  ),
  _SettingsItem(
    icon: Icons.flag_outlined,
    title: 'Goal & progress',
    onTap: (context) {
      // TODO: Navigate to goal & weight page
    },
  ),
  _SettingsItem(
    icon: Icons.language,
    title: 'Language',
    onTap: (context) {
      // TODO: Navigate to language settings page
    },
  ),
];

// Legal & Support Items
final List<_SettingsItem> _legalSupportItems = [
  _SettingsItem(
    icon: Icons.description_outlined,
    title: 'Terms and Conditions',
    onTap: (context) {
      // TODO: Navigate to terms page
    },
  ),
  _SettingsItem(
    icon: Icons.privacy_tip_outlined,
    title: 'Privacy Policy',
    onTap: (context) {
      // TODO: Navigate to privacy policy page
    },
  ),
  _SettingsItem(
    icon: Icons.email_outlined,
    title: 'Support Email',
    onTap: (context) {
      // TODO: Open email client
    },
  ),
  _SettingsItem(
    icon: Icons.campaign_outlined,
    title: 'Feature Request',
    onTap: (context) {
      // TODO: Navigate to feature request page
    },
  ),
];

// Account Management Items
final List<_SettingsItem> _accountItems = [
  _SettingsItem(
    icon: Icons.person_remove_outlined,
    title: 'Delete Account?',
    onTap: (context) {
      showDeleteAccountDialog(context);
    },
  ),
  _SettingsItem(
    icon: Icons.logout,
    title: 'Logout',
    onTap: (context) {
      handleLogout(context);
    },
  ),
];
