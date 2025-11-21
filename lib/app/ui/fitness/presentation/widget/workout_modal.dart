import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkoutModal extends StatelessWidget {
  final WorkoutDay workoutDay;
  final DateTime date;

  const WorkoutModal({
    super.key,
    required this.workoutDay,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPallete.backgroundColorBk,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutDay.day,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.whiteColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(date),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppPallete.whiteColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: AppPallete.whiteColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Focus
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppPallete.borderColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              workoutDay.focus,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB7F034),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Exercises
          Text(
            'Exercises',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPallete.whiteColor,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: workoutDay.exercises.length,
              itemBuilder: (context, index) {
                final exercise = workoutDay.exercises[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppPallete.borderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppPallete.borderColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppPallete.whiteColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB7F034).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${exercise.sets} sets × ${exercise.reps}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB7F034),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (exercise.notes != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          exercise.notes!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppPallete.whiteColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          // Tip
          if (workoutDay.tip != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      workoutDay.tip!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppPallete.whiteColor.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
      
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              context.push(
                '/workout',
                extra: {
                  'workoutDay': workoutDay,
                  'date': date,
                },
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Start Workout',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          ],
        ),
      ),
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

