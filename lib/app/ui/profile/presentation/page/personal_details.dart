import 'package:fitness/app/core/di.dart' as di;
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/profile/presentation/bloc/profile_bloc.dart';
import 'package:fitness/app/ui/profile/presentation/bloc/profile_event.dart';
import 'package:fitness/app/ui/profile/presentation/bloc/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class PersonalDetailsPage extends StatelessWidget {
  const PersonalDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ProfileBloc>()..add(LoadProfileEvent()),
      child: Scaffold(
        backgroundColor: AppPalete.backgroundColorBk,
        appBar: AppBar(
          backgroundColor: AppPalete.backgroundColorBk,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppPalete.whiteColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Personal Details',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppPalete.whiteColor,
            ),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppPalete.whiteColor,
                  ),
                );
              } else if (state is ProfileError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppPalete.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading profile',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppPalete.whiteColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ProfileBloc>().add(RefreshProfileEvent());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalete.whiteColor,
                          foregroundColor: AppPalete.backgroundColorBk,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (state is ProfileLoaded) {
                final profile = state.profile;
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _DetailCard(
                            icon: Icons.calendar_today_outlined,
                            label: 'Date of Birth',
                            value: _formatDateOfBirth(profile.dob),
                          ),
                          const SizedBox(height: 16),
                          _DetailCard(
                            icon: Icons.person_outline,
                            label: 'Gender',
                            value: _formatGender(profile.gender),
                          ),
                          const SizedBox(height: 16),
                          _DetailCard(
                            icon: Icons.height,
                            label: 'Height',
                            value: _formatHeight(profile.height),
                          ),
                          const SizedBox(height: 16),
                          _DetailCard(
                            icon: Icons.monitor_weight_outlined,
                            label: 'Weight',
                            value: _formatWeight(profile.weight),
                          ),
                        ]),
                      ),
                    ),
                  ],
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppPalete.whiteColor,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  /// Format date of birth from YYYY-MM-DD to readable format
  String _formatDateOfBirth(String? dob) {
    if (dob == null || dob.isEmpty) {
      return 'Not set';
    }

    try {
      final parts = dob.split('-');
      if (parts.length != 3) return dob;

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];

      return '${months[month - 1]} $day, $year';
    } catch (e) {
      return dob;
    }
  }

  /// Format gender
  String _formatGender(String? gender) {
    if (gender == null || gender.isEmpty) {
      return 'Not set';
    }
    return gender.substring(0, 1).toUpperCase() + gender.substring(1).toLowerCase();
  }

  /// Format height
  String _formatHeight(String? height) {
    if (height == null || height.isEmpty) {
      return 'Not set';
    }
    return height;
  }

  /// Format weight
  String _formatWeight(String? weight) {
    if (weight == null || weight.isEmpty) {
      return 'Not set';
    }
    return weight;
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppPalete.borderColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppPalete.whiteColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppPalete.whiteColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppPalete.whiteColor,
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

