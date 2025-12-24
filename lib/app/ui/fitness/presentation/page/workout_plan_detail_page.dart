import 'dart:io';
import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class WorkoutPlanDetailPage extends StatelessWidget {
  final StoredFitnessPlanEntity storedPlan;

  const WorkoutPlanDetailPage({
    Key? key,
    required this.storedPlan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final plan = storedPlan.workoutPlan.plan;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Hero Image Section
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.4,
            elevation: 0,
            snap: true,
            floating: true,
            stretch: true,
            backgroundColor: Colors.grey.shade50,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
              ],
              background: storedPlan.imagePath != null &&
                      File(storedPlan.imagePath!).existsSync()
                  ? Image.file(
                      File(storedPlan.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    )
                  : _buildImagePlaceholder(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(45),
              child: Transform.translate(
                offset: const Offset(0, 1),
                child: Container(
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${plan.goal} Workout Plan',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${plan.physiqueRating.toStringAsFixed(1)}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved on ${DateFormat('MMM dd, yyyy').format(storedPlan.createdAt)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Analysis Summary
                  _buildSection(
                    title: '📊 Analysis Summary',
                    child: Text(
                      plan.analysisSummary,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  // Goal and Focus
                  _buildSection(
                    title: '💥 Goal & Focus',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Goal', plan.goal),
                        const SizedBox(height: 8),
                        _buildInfoRow('Focus', plan.focus),
                        const SizedBox(height: 8),
                        _buildInfoRow('Training Split', plan.trainingSplit),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Equipment',
                          plan.equipment.join(', '),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                  // Weekly Split
                  _buildSection(
                    title: '🗓 Weekly Split',
                    child: Column(
                      children: plan.weeklySplit.days.map((day) {
                        return _buildWorkoutDayCard(day);
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 32),
                  // Training Guidelines
                  _buildSection(
                    title: '🏋️ Training Guidelines',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          'Rest Between Sets',
                          plan.trainingGuidelines.restBetweenSets,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Progressive Overload',
                          plan.trainingGuidelines.progressiveOverload,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Duration',
                          plan.trainingGuidelines.durationWeeks,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                  // Nutrition Guidelines
                  _buildSection(
                    title: '🥗 Nutrition Guidelines',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          'Protein per kg',
                          plan.nutritionGuidelines.proteinPerKg,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Calorie Surplus',
                          plan.nutritionGuidelines.calorieSurplus,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Hydration',
                          plan.nutritionGuidelines.hydration,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Sleep',
                          plan.nutritionGuidelines.sleep,
                        ),
                        if (plan.nutritionGuidelines.additionalNotes != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Additional Notes',
                            plan.nutritionGuidelines.additionalNotes!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (plan.extraTips.isNotEmpty) ...[
                    const Divider(height: 32),
                    // Extra Tips
                    _buildSection(
                      title: '🧠 Extra Tips',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: plan.extraTips.map((tip) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutDayCard(WorkoutDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  day.day,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  day.focus,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...day.exercises.map((exercise) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${exercise.sets} sets × ${exercise.reps}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            exercise.notes!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (day.tip != null && day.tip!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      day.tip!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.blue.shade100,
      child: Center(
        child: Icon(
          Icons.fitness_center,
          size: 64,
          color: Colors.blue.shade400,
        ),
      ),
    );
  }
}

