import 'dart:io';

import 'package:fitness/app/core/routes/app_router.dart';
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_bloc.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_event.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

enum AnalysisType {
  fullAnalysis,
  nutrientBreakdown,
}

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key, this.imagePath});

  final String? imagePath;

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  AnalysisType? _selectedAnalysisType;
  static const String _heroImageTag = 'food_image_hero';

  @override
  Widget build(BuildContext context) {
    return BlocListener<NutritionBloc, NutritionState>(
      listener: (context, state) {
        if (state is NutritionAnalysisLoaded) {
          // Navigate to analysis output page with hero animation
          context.push(
            ScreenPaths.nutritionAnalysis,
            extra: {
              'analysis': state.analysis,
              'imagePath': widget.imagePath,
              'heroTag': _heroImageTag,
            },
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
      child: BlocBuilder<NutritionBloc, NutritionState>(
        builder: (context, state) {
          final isLoading = state is NutritionLoading;
          
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              title: Text('Food Analysis', style: TextStyle(
                color: Colors.black,
              ),),
            ),
            floatingActionButton: isLoading
                ? const CircularProgressIndicator()
                : FloatingActionButton(
                    onPressed: widget.imagePath != null && _selectedAnalysisType != null
                        ? () {
                            final imageFile = File(widget.imagePath!);
                            context.read<NutritionBloc>().add(
                              AnalyzeFoodRequested(
                                image: imageFile,
                                extraInfo: _selectedAnalysisType == AnalysisType.fullAnalysis
                                    ? 'full_analysis'
                                    : 'nutrient_breakdown',
                              ),
                            );
                          }
                        : null,
                    child: const Icon(Icons.arrow_forward_ios),
                  ),
            body: widget.imagePath != null ? GestureDetector(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: AnimatedContainer(
                  height: MediaQuery.of(context).size.height * 0.75,
                  duration: Duration(milliseconds: 300),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100,
                        blurRadius: 30,
                        offset: Offset(0, 10),
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Hero(
                          tag: _heroImageTag,
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.55,
                            width: MediaQuery.of(context).size.width * 0.85,
                            margin: EdgeInsets.only(top: 10),
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Image.file(File(widget.imagePath!), fit: BoxFit.fitWidth),
                          ),
                        ),
                        SizedBox(height: 20,),
                        Text("Analyze Food:", style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                        ),),
                        SizedBox(height: 20,),
                        // Analysis type selection
                        _buildAnalysisTypeSelector(),
                        SizedBox(height: 20,), // Add bottom padding for scroll
                      ],
                    ),
                  ),
                ),
              ),
            ) : Center(
              child: Text(
                'No image selected.',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: AppPallete.whiteColor.withOpacity(0.7),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalysisTypeSelector() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _buildAnalysisOption(
                title: 'Full Analysis',
                description: 'Complete nutritional information including calories, macros, vitamins, and ingredients',
                value: AnalysisType.fullAnalysis,
                icon: Icons.analytics_outlined,
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: _buildAnalysisOption(
                title: 'Nutrient Breakdown',
                description: 'Detailed breakdown of macronutrients (protein, carbs, fats) and micronutrients',
                value: AnalysisType.nutrientBreakdown,
                icon: Icons.pie_chart_outline,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildAnalysisOption({
    required String title,
    required String description,
    required AnalysisType value,
    required IconData icon,
  }) {
    final isSelected = _selectedAnalysisType == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAnalysisType = value;
        });
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue.shade700 : Colors.black87,
                    ),
                  ),
                ),
                Radio<AnalysisType>(
                  value: value,
                  groupValue: _selectedAnalysisType,
                  onChanged: (AnalysisType? newValue) {
                    setState(() {
                      _selectedAnalysisType = newValue;
                    });
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}