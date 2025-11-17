import 'dart:async';

import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Helper class to get time-based greetings (reused from home.dart)
class GreetingHelper {
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  static String getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return '☀️';
    } else if (hour >= 12 && hour < 17) {
      return '🌤️';
    } else if (hour >= 17 && hour < 21) {
      return '🌆';
    } else {
      return '🌙';
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _greetingTimer;
  String _greeting = GreetingHelper.getGreeting();
  
  DateTime _selectedDate = DateTime.now();
  final ScrollController _dateScrollController = ScrollController();
  
  // Sample data - replace with actual data from your state management
  int _caloriesLeft = 0;
  int _caloriesBurned = 0;
  int _proteinGrams = 0;
  int _carbsGrams = 0;
  int _fatsGrams = 0;

  @override
  void initState() {
    super.initState();
    // Update greeting every minute
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _greeting = GreetingHelper.getGreeting();
        });
      }
    });
    
    // Scroll to selected date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _dateScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate() {
    final selectedIndex = _getDayIndex(_selectedDate);
    if (_dateScrollController.hasClients && selectedIndex >= 0) {
      final double itemWidth = 80.0;
      final double scrollOffset = selectedIndex * itemWidth - 
          (MediaQuery.of(context).size.width / 2 - itemWidth / 2);
      _dateScrollController.animateTo(
        scrollOffset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  int _getDayIndex(DateTime date) {
    final now = DateTime.now();
    final daysDiff = date.difference(now).inDays;
    return daysDiff + 3; // Start from 3 days ago
  }

  List<DateTime> _getWeekDates() {
    final List<DateTime> dates = [];
    final today = DateTime.now();
    for (int i = -3; i <= 3; i++) {
      dates.add(today.add(Duration(days: i)));
    }
    return dates;
  }

  String _getDayName(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColorBk,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // App Branding Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.apple,
                            color: AppPallete.whiteColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cal AI',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppPallete.whiteColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppPallete.borderColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_caloriesBurned',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppPallete.whiteColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Greeting (using flame emoji for fitness theme)
                  Row(
                    children: [
                      Text(
                        '$_greeting ',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppPallete.whiteColor,
                        ),
                      ),
                      const Text(
                        '🔥',
                        style: TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Date Selector
            SizedBox(
              height: 80,
              child: ListView.builder(
                controller: _dateScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _getWeekDates().length,
                itemBuilder: (context, index) {
                  final date = _getWeekDates()[index];
                  final isSelected = date.day == _selectedDate.day &&
                      date.month == _selectedDate.month &&
                      date.year == _selectedDate.year;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppPallete.borderColor.withOpacity(0.5)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppPallete.whiteColor.withOpacity(0.3)
                                    : AppPallete.whiteColor.withOpacity(0.1),
                                width: isSelected ? 2 : 1,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getDayName(date),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppPallete.whiteColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${date.day}',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppPallete.whiteColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calories Left Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppPallete.borderColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppPallete.borderColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_caloriesLeft',
                                style: GoogleFonts.poppins(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppPallete.whiteColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Calories left',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: AppPallete.whiteColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppPallete.borderColor.withOpacity(0.5),
                            ),
                            child: const Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Macronutrients Row
                    Row(
                      children: [
                        Expanded(
                          child: _MacroCard(
                            amount: '$_proteinGrams',
                            label: 'Protein over',
                            icon: Icons.restaurant_menu,
                            iconColor: Colors.red.shade400,
                            emoji: '🍗', // Chicken drumstick emoji
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MacroCard(
                            amount: '$_carbsGrams',
                            label: 'Carbs over',
                            icon: Icons.grass,
                            iconColor: Colors.amber.shade700,
                            emoji: '🌾', // Wheat emoji
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MacroCard(
                            amount: '$_fatsGrams',
                            label: 'Fats over',
                            icon: Icons.circle,
                            iconColor: Colors.blue.shade400,
                            emoji: '🥑', // Avocado emoji
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Recently Uploaded Section
                    Text(
                      'Recently uploaded',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.whiteColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Meal Placeholder Card
                    Container(
                      width: double.infinity,
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
                          // Placeholder for meal image
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppPallete.borderColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.image,
                              color: AppPallete.whiteColor,
                              size: 40,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 12,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppPallete.borderColor.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 12,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: AppPallete.borderColor.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap + to add your first meal of the day',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppPallete.whiteColor.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pagination Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppPallete.whiteColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppPallete.whiteColor.withOpacity(0.3),
                            border: Border.all(
                              color: AppPallete.whiteColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppPallete.whiteColor.withOpacity(0.3),
                            border: Border.all(
                              color: AppPallete.whiteColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppPallete.backgroundColorBk,
          border: Border(
            top: BorderSide(
              color: AppPallete.borderColor.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.home,
                  label: 'Home',
                  isSelected: true,
                  onTap: () {},
                ),
                _BottomNavItem(
                  icon: Icons.bar_chart,
                  label: 'Progress',
                  isSelected: false,
                  onTap: () {},
                ),
                _BottomNavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle add meal action
        },
        backgroundColor: AppPallete.whiteColor,
        child: const Icon(
          Icons.add,
          color: Colors.black,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Macro Card Widget
class _MacroCard extends StatelessWidget {
  final String amount;
  final String label;
  final IconData icon;
  final Color iconColor;
  final String? emoji;

  const _MacroCard({
    required this.amount,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.emoji,
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
          Text(
            '${amount}g',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppPallete.whiteColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (emoji != null)
                Text(
                  emoji!,
                  style: const TextStyle(fontSize: 20),
                )
              else
                Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppPallete.whiteColor.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Bottom Navigation Item Widget
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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

