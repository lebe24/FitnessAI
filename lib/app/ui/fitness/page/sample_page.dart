import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SamplePage extends StatefulWidget {
  const SamplePage({super.key});

  @override
  State<SamplePage> createState() => _SamplePageState();
}

class _SamplePageState extends State<SamplePage> {
  int _selectedTab = 0; // 0 = Today, 1 = Community
  int _selectedBottomNav = 0; // 0 = Home

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColorBk,
      body: SafeArea(
        child: Column(
          children: [
            // Header with tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tabs
                  Row(
                    children: [
                      _buildTab('Today', 0),
                      const SizedBox(width: 24),
                      _buildTab('Community', 1),
                    ],
                  ),
                  // Icons
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.bolt,
                              color: AppPallete.whiteColor,
                              size: 24,
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '1',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppPallete.whiteColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.notifications_outlined,
                        color: AppPallete.whiteColor,
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Main content with timeline
            Expanded(
              child: Stack(
                children: [
                  // Scrollable content
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 40, right: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Daily Refresh Section
                        _buildSectionHeader('Daily Refresh'),
                        const SizedBox(height: 16),
                        _buildVerseCard(),
                        const SizedBox(height: 40),
                        // Guided Scripture Section
                        _buildSectionHeader('Guided Scripture'),
                        const SizedBox(height: 16),
                        _buildGuidedScriptureCard(),
                        const SizedBox(height: 40),
                        // Guided Prayer Section
                        _buildSectionHeader('Guided prayer'),
                        const SizedBox(height: 16),
                        _buildGuidedPrayerCard(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  // Timeline indicator
                  Positioned(
                    left: 20,
                    top: 0,
                    bottom: 0,
                    child: Column(
                      children: [
                        const SizedBox(height: 120),
                        Container(
                          width: 2,
                          height: 200,
                          color: AppPallete.borderColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4DD0E1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppPallete.backgroundColorBk,
                              width: 2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppPallete.borderColor.withOpacity(0.5),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4DD0E1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppPallete.backgroundColorBk,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 2,
                          height: 100,
                          color: AppPallete.borderColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4DD0E1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppPallete.backgroundColorBk,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: AppPallete.whiteColor,
            ),
          ),
          const SizedBox(height: 8),
          if (isSelected)
            Container(
              width: 30,
              height: 3,
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            )
          else
            const SizedBox(height: 3),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppPallete.whiteColor,
      ),
    );
  }

  Widget _buildVerseCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C3E50).withOpacity(0.8),
            const Color(0xFF34495E).withOpacity(0.9),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.5),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verse of the day',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppPallete.whiteColor.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Psalm 31:24 KJV',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppPallete.whiteColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Be of good courage, and he shall strengthen your heart, All ye that hope in the LORD.',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppPallete.whiteColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // Engagement metrics
            Row(
              children: [
                _buildEngagementIcon(Icons.favorite, '1.095M'),
                const SizedBox(width: 20),
                _buildEngagementIcon(Icons.chat_bubble_outline, '15,534'),
                const SizedBox(width: 20),
                _buildEngagementIcon(Icons.share_outlined, '414.3k'),
                const Spacer(),
                Icon(
                  Icons.more_vert,
                  color: AppPallete.whiteColor.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppPallete.borderColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppPallete.whiteColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Send me this daily',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppPallete.whiteColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.close,
                    color: AppPallete.whiteColor,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementIcon(IconData icon, String count) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppPallete.whiteColor.withOpacity(0.7),
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppPallete.whiteColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildGuidedScriptureCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Courage in the Waiting',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppPallete.whiteColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: AppPallete.whiteColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '2-5 min',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppPallete.whiteColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppPallete.borderColor.withOpacity(0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF87CEEB),
                      const Color(0xFF4682B4),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppPallete.whiteColor,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidedPrayerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Need a moment with God?',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppPallete.whiteColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF9B59B6),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: AppPallete.whiteColor.withOpacity(0.2),
                  ),
                ),
                const Icon(
                  Icons.pan_tool,
                  color: AppPallete.whiteColor,
                  size: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppPallete.backgroundColorBk,
        border: Border(
          top: BorderSide(
            color: AppPallete.borderColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.menu_book, 'Bible', 1),
              _buildNavItem(Icons.checklist, 'Plans', 2),
              _buildNavItem(Icons.search, 'Discover', 3),
              _buildNavItem(Icons.person, 'You', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedBottomNav == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBottomNav = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected
                ? AppPallete.whiteColor
                : AppPallete.whiteColor.withOpacity(0.5),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? AppPallete.whiteColor
                  : AppPallete.whiteColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

}

