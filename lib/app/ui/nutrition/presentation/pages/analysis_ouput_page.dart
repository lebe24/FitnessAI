import 'dart:io';

import 'package:fitness/app/ui/nutrition/domain/entities/nutrition_analysis_entity.dart';
import 'package:fitness/app/ui/nutrition/domain/entities/stored_nutrition_analysis_entity.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_bloc.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_event.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

class AnalysisOutputPage extends StatefulWidget {
  const AnalysisOutputPage({
    super.key,
    this.analysis,
    this.imagePath,
    this.heroTag,
  });

  final NutritionAnalysisEntity? analysis;
  final String? imagePath;
  final String? heroTag;

  @override
  State<AnalysisOutputPage> createState() => _AnalysisOutputPageState();
}

class _AnalysisOutputPageState extends State<AnalysisOutputPage> {
  bool _isSaved = false;
  static const String _heroImageTag = 'food_image_hero';

  @override
  Widget build(BuildContext context) {
    if (widget.analysis == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analysis'),
        ),
        body: const Center(
          child: Text('No analysis data available'),
        ),
      );
    }

    final analysis = widget.analysis!;

    return BlocListener<NutritionBloc, NutritionState>(
      listener: (context, state) {
        if (state is NutritionAnalysisSaved) {
          setState(() {
            _isSaved = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Analysis saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is NutritionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            analysis.dishName,
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            IconButton(
              icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
              onPressed: _isSaved
                  ? null
                  : () {
                      final storedAnalysis = StoredNutritionAnalysisEntity(
                        id: const Uuid().v4(),
                        analysis: analysis,
                        imagePath: widget.imagePath,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      context.read<NutritionBloc>().add(
                            SaveNutritionAnalysisRequested(storedAnalysis),
                          );
                    },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Image
              if (widget.imagePath != null)
                Hero(
                  tag: widget.heroTag ?? _heroImageTag,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                    ),
                    child: Image.file(
                      File(widget.imagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // Product Info Card (similar to the reference image)
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100,
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dish Name and Healthiness Score
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                analysis.dishName,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getHealthinessColor(analysis.healthinessScore),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(analysis.healthinessScore * 100).toInt()}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Overall Rating
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Text(
                          analysis.overallRating,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Calories and Macros Summary
                      _buildMacrosSummary(analysis),

                      const SizedBox(height: 20),

                      // Macro Chart
                      _buildMacroChart(analysis),

                      const SizedBox(height: 20),

                      // Nutrient Breakdown
                      _buildNutrientBreakdown(analysis),

                      const SizedBox(height: 20),

                      // Ingredients
                      _buildIngredients(analysis),

                      const SizedBox(height: 20),

                      // Dietary Information
                      _buildDietaryInfo(analysis),

                      const SizedBox(height: 20),

                      // Workout Context
                      if (analysis.workoutContext.postWorkoutRecommended)
                        _buildWorkoutContext(analysis),

                      const SizedBox(height: 20),

                      // Notes
                      _buildNotes(analysis),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getHealthinessColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Widget _buildMacrosSummary(NutritionAnalysisEntity analysis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMacroItem(
            'Calories',
            '${analysis.estimatedNutrition.caloriesKcal}',
            Icons.local_fire_department,
            Colors.orange,
          ),
          _buildMacroItem(
            'Protein',
            '${analysis.estimatedNutrition.macros.proteinG.toInt()}g',
            Icons.fitness_center,
            Colors.blue,
          ),
          _buildMacroItem(
            'Carbs',
            '${analysis.estimatedNutrition.macros.carbsG.toInt()}g',
            Icons.energy_savings_leaf,
            Colors.green,
          ),
          _buildMacroItem(
            'Fats',
            '${analysis.estimatedNutrition.macros.fatG.toInt()}g',
            Icons.water_drop,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroChart(NutritionAnalysisEntity analysis) {
    final protein = analysis.macroEstimates.protein.percentage;
    final carbs = analysis.macroEstimates.carbohydrates.percentage;
    final fats = analysis.macroEstimates.fats.percentage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macronutrient Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    value: protein,
                    title: '${protein.toStringAsFixed(1)}%',
                    color: Colors.blue,
                    radius: 50,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: carbs,
                    title: '${carbs.toStringAsFixed(1)}%',
                    color: Colors.green,
                    radius: 50,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: fats,
                    title: '${fats.toStringAsFixed(1)}%',
                    color: Colors.purple,
                    radius: 50,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Protein', Colors.blue),
              _buildLegendItem('Carbs', Colors.green),
              _buildLegendItem('Fats', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildNutrientBreakdown(NutritionAnalysisEntity analysis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrient Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildNutrientRow('Protein', '${analysis.macroEstimates.protein.grams.toInt()}g', '${analysis.macroEstimates.protein.percentage.toStringAsFixed(1)}%'),
          _buildNutrientRow('Carbohydrates', '${analysis.macroEstimates.carbohydrates.grams.toInt()}g', '${analysis.macroEstimates.carbohydrates.percentage.toStringAsFixed(1)}%'),
          _buildNutrientRow('Fats', '${analysis.macroEstimates.fats.grams.toInt()}g', '${analysis.macroEstimates.fats.percentage.toStringAsFixed(1)}%'),
          _buildNutrientRow('Fiber', '${analysis.macroEstimates.fiber.grams.toInt()}g', '${analysis.macroEstimates.fiber.percentage.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                percentage,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredients(NutritionAnalysisEntity analysis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Identified Ingredients',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: analysis.identifiedIngredients.map((ingredient) {
              return Chip(
                label: Text(
                  ingredient,
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                backgroundColor: Colors.blue.shade50,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryInfo(NutritionAnalysisEntity analysis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dietary Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (analysis.dietarySafetyConstraints.allergens.isNotEmpty) ...[
            Text(
              'Allergens:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...analysis.dietarySafetyConstraints.allergens.map((allergen) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '• ${allergen.name} (${allergen.severity}) - from ${allergen.source}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
          Text(
            'Dietary Restrictions:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (analysis.dietarySafetyConstraints.dietaryRestrictions.glutenFree)
                _buildDietaryChip('Gluten Free', Colors.green),
              if (analysis.dietarySafetyConstraints.dietaryRestrictions.vegan)
                _buildDietaryChip('Vegan', Colors.green),
              if (analysis.dietarySafetyConstraints.dietaryRestrictions.vegetarian)
                _buildDietaryChip('Vegetarian', Colors.green),
              if (analysis.dietarySafetyConstraints.dietaryRestrictions.halal)
                _buildDietaryChip('Halal', Colors.green),
              if (analysis.dietarySafetyConstraints.dietaryRestrictions.dairyFree)
                _buildDietaryChip('Dairy Free', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 11),
      ),
      backgroundColor: color.withOpacity(0.2),
      side: BorderSide(color: color),
    );
  }

  Widget _buildWorkoutContext(NutritionAnalysisEntity analysis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Post-Workout Recommended',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Best timing: ${analysis.workoutContext.bestTimingHoursAfterWorkout} hours after workout',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            const SizedBox(height: 8),
            ...analysis.workoutContext.why.map((reason) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '• $reason',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes(NutritionAnalysisEntity analysis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...analysis.notes.map((note) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      note,
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}





