import  'dart:io';

import 'package:fitness/app/core/common/widget/appWidget.dart';
import 'package:fitness/app/ui/nutrition/domain/entities/nutrition_analysis_entity.dart';
import 'package:fitness/app/ui/nutrition/domain/entities/stored_nutrition_analysis_entity.dart';
import 'package:fitness/app/ui/nutrition/data/models/stored_nutrition_analysis_model.dart';
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
        }else if(state is NutritionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: MediaQuery.of(context).size.height * 0.6,
              elevation: 0,
              snap: true,
              floating: true,
              stretch: true,
              backgroundColor: Colors.grey.shade50,
              flexibleSpace: FlexibleSpaceBar(
              stretchModes: [
                StretchMode.zoomBackground,
              ],
              background: Image.file(
                File(widget.imagePath!),
                fit: BoxFit.cover,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(45),
              child: Transform.translate(
                offset: Offset(0, 1),
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    )
                  ),
                ),
              ),
            )),
            SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  height: MediaQuery.of(context).size.height * 0.55,
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: SingleChildScrollView(

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color:Colors.black,
                            borderRadius: BorderRadius.circular(5)
                          ),
                          child:Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Meal Name",
                              style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white
                            ),
                          ),
                          )
                        ),
                        SizedBox(height: 10,),
                        Text(
                          analysis.dishName,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10,),
                    
                        // Calories and Macros Summary
                        _buildMacrosSummary(analysis),
                        SizedBox(height: 20,),
                        Container(
                          decoration: BoxDecoration(
                            
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            
                            children: [
                              Text(
                                "${analysis.overallRating} : ",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              Text(
                                '${(analysis.healthinessScore * 100).toInt()}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _getHealthinessColor(analysis.healthinessScore),
                                ),
                              ),
                                
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Nutrient Breakdown
                        _buildNutrientBreakdown(analysis),
                    
                        const SizedBox(height: 20),
                    
                        // Macro Chart
                        _buildMacroChart(analysis),
                    
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

                      SizedBox(
                        width: double.infinity,
                        child: _isSaved
                            ? ElevatedButton(
                                onPressed: null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Meal Saved",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : AppWidgets.roundbtnText(
                                onPressed: () {
                                  _saveMeal(context);
                                },
                                text: "Save Meal",
                              ),
                      )
                    ],),
                  ),
                )
              ])
            )
          ],
        )
      ),
    );
  }

  void _saveMeal(BuildContext context) {
    if (widget.analysis == null) return;

    final now = DateTime.now();
    final storedAnalysis = StoredNutritionAnalysisModel(
      id: const Uuid().v4(),
      analysis: widget.analysis!,
      imagePath: widget.imagePath,
      createdAt: now,
      updatedAt: now,
    );

    context.read<NutritionBloc>().add(
          SaveNutritionAnalysisRequested(storedAnalysis),
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
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12),
                ),
                backgroundColor: const Color(0xFF057E43)
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















