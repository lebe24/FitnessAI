import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ======= Exercise Hero Page ========

class ExerciseHeroPage extends StatelessWidget {
  final Exercise exercise;
  final int exerciseIndex;
  final VoidCallback onComplete;

  const ExerciseHeroPage({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.onComplete,
  });

  List<Color> _getGradientColors() {
    return [
      const Color(0xFF2C3E50).withOpacity(0.8),
      const Color(0xFF34495E).withOpacity(0.9),
      Colors.black.withOpacity(0.9),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppPallete.whiteColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Exercise ${exerciseIndex + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppPallete.whiteColor,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              // Exercise content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Exercise name
                      Text(
                        exercise.name,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.whiteColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Sets and reps info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppPallete.whiteColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppPallete.whiteColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${exercise.sets}',
                                  style: GoogleFonts.inter(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppPallete.whiteColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sets',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppPallete.whiteColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              color: AppPallete.whiteColor.withOpacity(0.3),
                            ),
                            Column(
                              children: [
                                Text(
                                  exercise.reps,
                                  style: GoogleFonts.inter(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppPallete.whiteColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Reps',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppPallete.whiteColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (exercise.notes != null) ...[
                        const SizedBox(height: 32),
                        Text(
                          'Instructions',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppPallete.whiteColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppPallete.whiteColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppPallete.whiteColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            exercise.notes!,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppPallete.whiteColor.withOpacity(0.9),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              // Complete button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: GestureDetector(
                  onTap: onComplete,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Complete Exercise',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppPallete.whiteColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}