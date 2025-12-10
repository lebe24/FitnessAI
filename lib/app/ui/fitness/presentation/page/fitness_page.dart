import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:fitness/app/core/common/widget/greeting.dart';
import 'package:fitness/app/core/constant/assets.dart';
import 'package:fitness/app/core/di.dart';
import 'package:fitness/app/core/routes/app_router.dart';
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/auth/domain/usecase/get_current_user.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_bloc.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_event.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_state.dart';
import 'package:fitness/app/ui/fitness/presentation/method/fitness.dart';
import 'package:fitness/app/ui/fitness/presentation/page/motivate_page.dart';
import 'package:fitness/app/ui/fitness/presentation/page/save_page.dart';
import 'package:fitness/app/ui/fitness/presentation/widget/workout_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class FitnessPage extends StatefulWidget {
  const FitnessPage({super.key});

  @override
  State<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends State<FitnessPage> with WidgetsBindingObserver {
  Timer? _greetingTimer;
  String _greeting = GreetingHelper.getGreeting();
  String _emoji = GreetingHelper.getGreetingEmoji();

  DateTime _selectedDate = DateTime.now();
  final ScrollController _dateScrollController = ScrollController();
  bool _hasLoadedInitialData = false;
  DateTime? _lastReloadTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load fitness plans
    context.read<FitnessBloc>().add(const LoadFitnessPlans());
    _hasLoadedInitialData = true;
    _lastReloadTime = DateTime.now();

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

  Future<void> _scanFoodItem() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // Navigate to nutrition page with the image path
        context.push(
          ScreenPaths.nutrition,
          extra: {'imagePath': image.path},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing camera: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _hasLoadedInitialData) {
      // Reload plans when app comes back to foreground
      context.read<FitnessBloc>().add(const LoadFitnessPlans());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload plans when page becomes visible again (e.g., returning from WorkoutPage)
    // Only reload if it's been more than 500ms since last reload to avoid excessive reloads
    if (_hasLoadedInitialData && mounted) {
      final now = DateTime.now();
      if (_lastReloadTime == null || 
          now.difference(_lastReloadTime!).inMilliseconds > 500) {
        _lastReloadTime = now;
        // Use a small delay to ensure we're back on this page
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            context.read<FitnessBloc>().add(const LoadFitnessPlans());
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
            // Fixed header section
            _homeHeader(context),
            const SizedBox(height: 10),
            _greetings(),
            // Fixed Date Selector
            _workoutDates(),
            // Scrollable content section
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Access the Camera to scan Item for Analysis
                    GestureDetector(
                      onTap: _scanFoodItem,
                      child: _customWidget(context,"Tap to Scan Food Item",
                      null,
                      ImagePath.foodScan,'Scan food items to get nutritional information and stay on top of your diet.')),
                    const SizedBox(height: 20),
                    Text(
                      'Access Your Motivation',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppPalete.whiteColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: (){
                        FitnessMethod.dialogBuilder(
                          context, 
                          _motivateDialog(),
                        );
                      },
                      child: FitnessMethod.banner(context)
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your Saved Data',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppPalete.whiteColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<FitnessBloc, FitnessState>(
                      builder: (context, state) {
                        String? savedImagePath;
                        if (state is FitnessLoaded && state.plans.isNotEmpty) {
                          // Get the most recent plan's image
                          final mostRecentPlan = state.plans.first;
                          savedImagePath = mostRecentPlan.imagePath;
                        }
                        return GestureDetector(
                          onTap: () {
                            // Navigate to history or settings page
                            Navigator.push(context, 
                              MaterialPageRoute(
                                builder: (context) => const SavedPage(),
                              ),
                            );
                            
                          },
                          child: _customWidget(
                            context,
                            "Check out your Saved Data",
                            savedImagePath,
                            null,
                            'Review your past food scans and Workout Plans time.',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  // ignore: unused_element
  SizedBox _mealWidget(BuildContext context) {
    return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3, // You can change this to a dynamic list later
                    itemBuilder: (context, index) {
                      List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner'];
                      List<String> mealImages = [ImagePath.breakfastImage, ImagePath.lunchImage, ImagePath.dinnerImage];
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < 2 ? 12 : 0, // Add spacing between items
                        ),
                        child: meal_suggestion(
                          context, mealTypes[index], mealImages[index]),
                      );
                    },
                  ),
                );
}

  BlocBuilder<FitnessBloc, FitnessState> _workoutDates() {
    return BlocBuilder<FitnessBloc, FitnessState>(
      builder: (context, state) {
        final workoutMappings = state is FitnessLoaded
            ? state.workoutMappings
            : <DateTime, dynamic>{};
        Set<DateTime> completedDates = <DateTime>{};
        // if (state is FitnessLoaded) {
        //   try {
        //     final loadedState = state as FitnessLoaded;
        //     completedDates = loadedState.completedDates.isNotEmpty 
        //         ? loadedState.completedDates 
        //         : <DateTime>{};
        //   } catch (e) {
        //     completedDates = <DateTime>{};
        //   }
        // }
              
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
              final isCompleted = completedDates.contains(normalizedDate);
              
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
                              shape: BoxShape.rectangle,
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
                                  ? AppPalete.borderColor.withOpacity(0.6)
                                  : isCompleted
                                      ? Colors.red.withOpacity(0.6)
                                      : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppPalete.whiteColor.withOpacity(0.4)
                                    : isCompleted
                                        ? Colors.red.withOpacity(0.8)
                                        : hasWorkout
                                            ? const Color(0xFFB7F034).withOpacity(0.6)
                                            : AppPalete.whiteColor.withOpacity(0.1),
                                width: isSelected ? 2 : (isCompleted || hasWorkout) ? 2 : 1,
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
                                      color: AppPalete.whiteColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${date.day}',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppPalete.whiteColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Workout indicator dot
                          if (hasWorkout && !isSelected && !isCompleted)
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
                          // Completed indicator dot
                          if (isCompleted && !isSelected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
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
    );
}

Row _greetings() {
  return Row(
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
    );
  }


// Note AI:  Monitor day workout Streak and increment when the daily workout is completed
  Widget _homeHeader(BuildContext context) {
    return BlocBuilder<FitnessBloc, FitnessState>(
      builder: (context, state) {
        final _streak = state is FitnessLoaded ? state.streak : 0;
        // if (state is FitnessLoaded) {
        //   try {
        //     final loadedState = state as FitnessLoaded;
        //     streak = loadedState.streak > 0 ? loadedState.streak : 0;
        //   } catch (e) {
        //     streak = 0;
        //   }
        // }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _fitnessHeader(),
            GestureDetector(
              onTap: () {
                // Handle tap event
                FitnessMethod.dialogBuilder(
                  context,
                  _streakDialog(_streak)
                  // const CustomDialog(),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppPalete.whiteColor.withOpacity(0.2),
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
                    //Note for AI:  Increment streak as Day workout is completed
                    Text(
                      '$_streak',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppPalete.whiteColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _streakDialog(int streak){
    return SizedBox(
      width: 400,
      height: 300,
      child: Card(
        child: Center(child: Text("$streak",style: TextStyle(fontSize: 150,fontWeight: FontWeight.bold),)),
      ),
    );
  }

  SizedBox meal_suggestion(BuildContext context,String mealType, String imagePath) {
    return SizedBox(
                width: MediaQuery.of(context).size.width * 0.32,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Image.asset(
                          imagePath,
                          height: MediaQuery.of(context).size.height * 0.25,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 20,
                      child: Text(
                        textAlign: TextAlign.center,
                        "Tap \n For \n$mealType ",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppPalete.whiteColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
  }

  Container _customWidget(
    BuildContext context,
    String text,
    String? imagePath,
    String? imageString,
    String description,
  ) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.19,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalete.whiteColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.3,
              height: double.infinity,
              child:imageString != null ? Image.asset(
                imageString,
                fit: BoxFit.cover,
                )  :imagePath != null
                  ? FutureBuilder<bool>(
                      future: File(imagePath).exists(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildImagePlaceholder();
                        }
                        if (snapshot.hasData && snapshot.data == true) {
                          return Image.file(
                            File(imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                          );
                        }
                        return _buildImagePlaceholder();
                      },
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppPalete.whiteColor,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppPalete.whiteColor.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppPalete.borderColor.withOpacity(0.3),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppPalete.whiteColor,
          size: 40,
        ),
      ),
    );
  }

  Row _fitnessHeader() {
    return Row(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Image.asset(ImagePath.appLogo))
      ],
    );
  }
}

class _motivateDialog extends StatelessWidget {
  const _motivateDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 400,
      child:  Card(
        child: Column(
          children: [
            Center(
              child: Text('History Page Coming Soon!'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MotivatePage(tone: 'aggressive',),
                  ),
                );
              },
              child: Text('Next',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppPalete.borderColor,
                ),
    
              ),
            ),
          ],
        ),
      ),
    );
  }
}