import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/fitness/presentation/widget/exercise_hero_page.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AiChat {
  none,
  active,
}

class WorkoutPage extends StatefulWidget {
  final WorkoutDay? workoutDay;
  final DateTime? date;

  const WorkoutPage({
    super.key,
    this.workoutDay,
    this.date,
  });

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  AiChat _aiChatState = AiChat.none;
  final Set<int> _completedExercises = {};
  int _currentExerciseIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.workoutDay?.exercises.isEmpty ?? true) {
      _currentExerciseIndex = -1;
    }
  }

  void _completeExercise(int index) {
    setState(() {
      _completedExercises.add(index);
      if (_currentExerciseIndex == index && index < (widget.workoutDay?.exercises.length ?? 0) - 1) {
        _currentExerciseIndex = index + 1;
      }
    });
  }

  bool _isExerciseActive(int index) {
    return _currentExerciseIndex == index && !_completedExercises.contains(index);
  }

  bool _isExerciseDone(int index) {
    return _completedExercises.contains(index);
  }

  void _handleExerciseDoubleTap(int index) {
    if (_isExerciseActive(index)) {
      // Navigate to hero page for active exercise
      final exercise = widget.workoutDay?.exercises[index];
      if (exercise != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExerciseHeroPage(
              exercise: exercise,
              exerciseIndex: index,
              onComplete: () {
                _completeExercise(index);
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    } else {
      // Show snackbar if not the current exercise
      ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please complete previous exercises first to move forward.')),
      );
    }
  }

  List<Color> _getActiveGradientColors() {
    return [
      const Color(0xFF2C3E50).withOpacity(0.8),
      const Color(0xFF34495E).withOpacity(0.9),
      Colors.black.withOpacity(0.9),
    ];
  }

  Widget? _buildFloatingActionButton() {
    switch (_aiChatState) {
      case AiChat.none:
        return FloatingActionButton(
          key: const ValueKey('fab_none'),
          onPressed: _toggleAiChat,
          backgroundColor: AppPallete.backgroundColorBk,
          child: const Icon(Icons.chat_bubble, color: Colors.white),
        );
      case AiChat.active:
        return null; // Modal is shown, hide FAB
    }
  }

  void _toggleAiChat() {
    if (_aiChatState == AiChat.none) {
      setState(() {
        _aiChatState = AiChat.active;
      });
      _showChatModal();
    } else {

      setState(() {
        _aiChatState = AiChat.none;
      });
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Close modal if open
      }
    }
  }

  void _showChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppPallete.backgroundColorBk,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPallete.whiteColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Chat header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI-Chat Assistant',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.whiteColor,
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleAiChat,
                      icon: const Icon(
                        Icons.close,
                        color: AppPallete.whiteColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              // Chat content
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'You Can Doubletap on your Excercise Card to See More Details',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: AppPallete.whiteColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
              // Chat input area
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: GoogleFonts.inter(color: AppPallete.whiteColor),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: GoogleFonts.inter(
                            color: AppPallete.whiteColor.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: AppPallete.whiteColor.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      onPressed: () {
                        // Send message
                      },
                      backgroundColor: AppPallete.borderColor,
                      child: const Icon(Icons.send, color: AppPallete.whiteColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Reset state when modal is dismissed
      if (_aiChatState == AiChat.active) {
        setState(() {
          _aiChatState = AiChat.none;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.workoutDay?.exercises ?? [];
    return Scaffold(
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: _buildFloatingActionButton(),
      ),
      backgroundColor: AppPallete.backgroundColorBk,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _dateHeader(),
                  _notificationHeader(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildSectionHeader('Daily Exercise'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 40, right: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Note to Ai: Map the card excise here after each card a sizedbox of 16 height should follow.
                        if (exercises.isNotEmpty) ...[
                          // First exercise - no section header
                          _buildExerciseCard(0),
                          const SizedBox(height: 16),
                          // Rest of exercises with section header
                          ...exercises.asMap().entries.skip(1).map((entry) {
                            final index = entry.key;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _buildExerciseCard(index),
                                const SizedBox(height: 16),
                              ],
                            );
                          }),
                        ] else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Text(
                                'No exercises available',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: AppPallete.whiteColor.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Progress Indicator Positioned
                  _progressIndicator(exercises.length),
                ],
              )
            )
          ],
        )
      )
    );
  }

// Note to Ai: Do not use this widget for the first excise but use it for the rest of the following excises
// ======= Exercise Header ========
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

// Note To Ai: This card should be used when exercise card is active and unused when card is done
// ======= Exercise Card Widget ========

  Widget _buildExerciseCard(int index) {
    final exercises = widget.workoutDay?.exercises ?? [];
    if (index >= exercises.length) return const SizedBox.shrink();

    final exercise = exercises[index];
    final isActive = _isExerciseActive(index);
    final isDone = _isExerciseDone(index);

    // If exercise is done, don't show the card
    if (isDone) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onDoubleTap: () => _handleExerciseDoubleTap(index),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? [
                    const Color(0xFF2C3E50).withOpacity(0.8),
                    const Color(0xFF34495E).withOpacity(0.9),
                    Colors.black.withOpacity(0.9),
                  ]
                : [
                    const Color(0xFF1A1A1A).withOpacity(0.6),
                    const Color(0xFF1A1A1A).withOpacity(0.7),
                    const Color(0xFF1A1A1A).withOpacity(0.8),
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
                exercise.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppPallete.whiteColor.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${exercise.sets} sets × ${exercise.reps}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppPallete.whiteColor.withOpacity(0.7),
                ),
              ),
              if (exercise.notes != null) ...[
                const SizedBox(height: 16),
                Text(
                  exercise.notes!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppPallete.whiteColor.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Engagement metrics
              Row(
                children: [
                  const Spacer(),
                  Icon(
                    Icons.more_vert,
                    color: AppPallete.whiteColor.withOpacity(0.7),
                    size: 20,
                  ),
                ],
              ),
              if (isActive) ...[
                const SizedBox(height: 16),
                // Action button - only show when active
                GestureDetector(
                  onTap: () => _completeExercise(index),
                  child: Container(
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
                          Icons.check_circle_outline,
                          color: AppPallete.whiteColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Complete Exercise',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppPallete.whiteColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  // ======= Progress Indicator ========

  // Note for Ai: when maping the progress indictor to the exercises the when an exercise is done the circle width should be 18X18 and when its active it should be 18X18 

  Positioned _progressIndicator(int totalExercises) {
    final exercises = widget.workoutDay?.exercises ?? [];
    if (exercises.isEmpty) {
      return const Positioned(left: 0, top: 0, bottom: 0, child: SizedBox());
    }

    return Positioned(
      left: 20,
      top: 0,
      bottom: 0,
      child: Column(
        children: [
          const SizedBox(height: 100),
          // Top line
          Container(
            width: 2,
            height: 40,
            color: AppPallete.borderColor.withOpacity(0.5),
          ),
          // Exercise indicators
          ...exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final isActive = _isExerciseActive(index);
            final isDone = _isExerciseDone(index);
            final isLast = index == exercises.length - 1;
            final isFirst = index == 0;

            return Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Circle indicator - 18x18 for both active and done
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF4DD0E1) // Done - cyan
                          : isActive
                              ? const Color(0xFFB7F034) // Active - green
                              : AppPallete.borderColor.withOpacity(0.3), // Pending - gray
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppPallete.backgroundColorBk,
                        width: 2,
                      ),
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 8),
                    // Connecting line - use Expanded to fill available space
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isDone
                            ? const Color(0xFF4DD0E1).withOpacity(0.5)
                            : AppPallete.borderColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  


  // ======== Notification Header ========

  Row _notificationHeader() {
    return Row(
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
    );
  }

  // ======= Date Header ========

  Column _dateHeader() {
    final dayName = widget.workoutDay?.day ?? 'Today';
    final date = widget.date ?? DateTime.now();
    final dateStr = _formatDate(date);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "$dayName : ",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppPallete.whiteColor,
              ),
            ),
            Text(
          dateStr,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppPallete.whiteColor.withOpacity(0.7),
          ),
        ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: 30,
          height: 3,
          decoration: const BoxDecoration(
            color: Color(0xFFB7F034),
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

