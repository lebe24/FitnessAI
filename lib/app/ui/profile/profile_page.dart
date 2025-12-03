import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: _UserProfileSection(),
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
    );
  }
}

// User Profile Section Widget
class _UserProfileSection extends StatelessWidget {
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
            child: const Center(
              child: Text(
                'e',
                style: TextStyle(
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
                  'emmanuel philip amadikwa',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppPallete.whiteColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '24 years old',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: AppPallete.whiteColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  final VoidCallback? onTap;
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
          onTap: onTap,
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
  final VoidCallback? onTap;

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
    onTap: () {
      // TODO: Navigate to personal details page
    },
  ),
  _SettingsItem(
    icon: Icons.refresh,
    title: 'Adjust macronutrients',
    onTap: () {
      // TODO: Navigate to macronutrients page
    },
  ),
  _SettingsItem(
    icon: Icons.flag_outlined,
    title: 'Goal & current weight',
    onTap: () {
      // TODO: Navigate to goal & weight page
    },
  ),
  _SettingsItem(
    icon: Icons.history,
    title: 'Weight history',
    onTap: () {
      // TODO: Navigate to weight history page
    },
  ),
  _SettingsItem(
    icon: Icons.language,
    title: 'Language',
    onTap: () {
      // TODO: Navigate to language settings page
    },
  ),
];

// Legal & Support Items
final List<_SettingsItem> _legalSupportItems = [
  _SettingsItem(
    icon: Icons.description_outlined,
    title: 'Terms and Conditions',
    onTap: () {
      // TODO: Navigate to terms page
    },
  ),
  _SettingsItem(
    icon: Icons.privacy_tip_outlined,
    title: 'Privacy Policy',
    onTap: () {
      // TODO: Navigate to privacy policy page
    },
  ),
  _SettingsItem(
    icon: Icons.email_outlined,
    title: 'Support Email',
    onTap: () {
      // TODO: Open email client
    },
  ),
  _SettingsItem(
    icon: Icons.campaign_outlined,
    title: 'Feature Request',
    onTap: () {
      // TODO: Navigate to feature request page
    },
  ),
];

// Account Management Items
final List<_SettingsItem> _accountItems = [
  _SettingsItem(
    icon: Icons.person_remove_outlined,
    title: 'Delete Account?',
    onTap: () {
      // TODO: Show delete account confirmation dialog
    },
  ),
  _SettingsItem(
    icon: Icons.logout,
    title: 'Logout',
    onTap: () {
      // TODO: Implement logout functionality
    },
  ),
];
