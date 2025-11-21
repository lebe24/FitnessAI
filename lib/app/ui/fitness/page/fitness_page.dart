import 'dart:async';

import 'package:fitness/app/core/common/widget/greeting.dart';
import 'package:fitness/app/core/di.dart';
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/auth/domain/usecase/get_current_user.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_bloc.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_event.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_state.dart';
import 'package:fitness/app/ui/fitness/presentation/widget/workout_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class FitnessPage extends StatefulWidget {
  const FitnessPage({super.key});

  @override
  State<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends State<FitnessPage> {
  Timer? _greetingTimer;
  String _greeting = GreetingHelper.getGreeting();
  String _emoji = GreetingHelper.getGreetingEmoji();

  DateTime _selectedDate = DateTime.now();
  final ScrollController _dateScrollController = ScrollController();

  int _caloriesBurned = 0;

  @override
  void initState() {
    super.initState();
    // Load fitness plans
    context.read<FitnessBloc>().add(const LoadFitnessPlans());

    // Update greeting every minute to handle time changes
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _greeting = GreetingHelper.getGreeting();
          _emoji = GreetingHelper.getGreetingEmoji();
        });
      }
    });

    // Scroll to selected date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
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
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    final daysDiff = selected.difference(today).inDays;
    return daysDiff; // Start from today (index 0)
  }

  List<DateTime> _getWeekDates() {
    final List<DateTime> dates = [];
    final today = DateTime.now();
    // Start from today and show next 7 days (including today)
    for (int i = 0; i < 7; i++) {
      dates.add(today.add(Duration(days: i)));
    }
    return dates;
  }

  String _getDayName(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _shortenDisplayName(String name, {int maxLength = 15}) {
    if (name.length <= maxLength) {
      return name;
    }
    return '${name.substring(0, maxLength)}...';
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return  SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      'BeFit',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.whiteColor,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    // Handle tap event
                    debugPrint('Calories Burned tapped');
                  },
                  child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppPallete.whiteColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
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
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  "$_greeting ",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  _emoji,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    final getCurrentUser = sl<GetCurrentUser>();
                    final user = getCurrentUser();
                    final displayName = user?.name ?? 
                                        user?.email ?? 
                                        'User';
                    return Text(
                      _shortenDisplayName(displayName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.bold),
                    );
                  },
              ),
              ],
            ),
            
            // Date Selector
            BlocBuilder<FitnessBloc, FitnessState>(
              builder: (context, state) {
                final workoutMappings = state is FitnessLoaded
                    ? state.workoutMappings
                    : <DateTime, dynamic>{};

                return SizedBox(
                  height: 80,
                  child: ListView.builder(
                    controller: _dateScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _getWeekDates().length,
                    itemBuilder: (context, index) {
                      final date = _getWeekDates()[index];
                      final normalizedDate =
                          DateTime(date.year, date.month, date.day);
                      final isSelected = date.day == _selectedDate.day &&
                          date.month == _selectedDate.month &&
                          date.year == _selectedDate.year;
                      final hasWorkout = workoutMappings.containsKey(normalizedDate);
                      final workoutMapping = workoutMappings[normalizedDate];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                          context.read<FitnessBloc>().add(DateSelected(date));

                          // Show workout modal if there's a workout for this date
                          if (hasWorkout && workoutMapping?.workoutDay != null) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => DraggableScrollableSheet(
                                initialChildSize: 0.7,
                                minChildSize: 0.5,
                                maxChildSize: 0.9,
                                builder: (context, scrollController) =>
                                    WorkoutModal(
                                  workoutDay: workoutMapping!.workoutDay!,
                                  date: date,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.white.withAlpha(100),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                      color: isSelected
                                          ? AppPallete.borderColor.withOpacity(0.6)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppPallete.whiteColor.withOpacity(0.4)
                                            : hasWorkout
                                                ? const Color(0xFFB7F034).withOpacity(0.6)
                                                : AppPallete.whiteColor.withOpacity(0.1),
                                        width: isSelected ? 2 : hasWorkout ? 2 : 1,
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
                                  // Workout indicator dot
                                  if (hasWorkout && !isSelected)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFB7F034),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                'Fitness Page',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}