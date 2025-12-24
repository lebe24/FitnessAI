import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/core/di.dart';
import 'package:fitness/app/core/routes/app_router.dart';
import 'package:fitness/app/ui/nutrition/domain/entities/stored_nutrition_analysis_entity.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_bloc.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_event.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_state.dart';
import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_bloc.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

enum SavedItemType { meal, workoutPlan }

class SavedItem {
  final SavedItemType type;
  final String id;
  final String title;
  final String? imagePath;
  final String description;
  final DateTime createdAt;
  final dynamic data; // StoredNutritionAnalysisEntity or StoredFitnessPlanEntity

  SavedItem({
    required this.type,
    required this.id,
    required this.title,
    this.imagePath,
    required this.description,
    required this.createdAt,
    required this.data,
  });
}

class SavedPage extends StatefulWidget {
  const SavedPage({Key? key}) : super(key: key);

  @override
  _SavedPageState createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  int _current = 0;
  SavedItem? _selectedItem;
  final CarouselSliderController _carouselController = CarouselSliderController();
  List<SavedItem> _savedData = [];

  @override
  void initState() {
    super.initState();
    // Request nutrition analyses when bloc is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NutritionBloc>().add(const GetAllNutritionAnalysesRequested());
      }
    });
  }

  void _loadSavedData() {
    if (!mounted) return;
    
    final List<SavedItem> items = [];

    // Get nutrition analyses from NutritionBloc
    final nutritionState = context.read<NutritionBloc>().state;
    if (nutritionState is AllNutritionAnalysesLoaded) {
      for (var analysis in nutritionState.analyses) {
        items.add(SavedItem(
          type: SavedItemType.meal,
          id: analysis.id,
          title: analysis.analysis.dishName,
          imagePath: analysis.imagePath,
          description: '${analysis.analysis.estimatedNutrition.caloriesKcal} kcal • ${(analysis.analysis.healthinessScore * 100).toInt()}% healthy',
          createdAt: analysis.createdAt,
          data: analysis,
        ));
      }
    }

    // Get fitness plans from FitnessBloc
    final fitnessState = context.read<FitnessBloc>().state;
    if (fitnessState is FitnessLoaded) {
      for (var plan in fitnessState.plans) {
        items.add(SavedItem(
          type: SavedItemType.workoutPlan,
          id: plan.id,
          title: '${plan.workoutPlan.plan.goal} Workout Plan',
          imagePath: plan.imagePath,
          description: '${plan.workoutPlan.plan.trainingSplit} • ${plan.workoutPlan.plan.weeklySplit.days.length} days/week',
          createdAt: plan.createdAt,
          data: plan,
        ));
      }
    }

    // Sort by creation date (newest first)
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mounted) {
      setState(() {
        _savedData = items;
      });
    }
  }

  void _navigateToDetail(SavedItem item) {
    if (item.type == SavedItemType.meal) {
      final storedAnalysis = item.data as StoredNutritionAnalysisEntity;
      context.push(
        ScreenPaths.nutritionAnalysis,
        extra: {
          'analysis': storedAnalysis.analysis,
          'imagePath': storedAnalysis.imagePath,
        },
      );
    } else {
      // item.type == SavedItemType.workoutPlan
      final storedPlan = item.data as StoredFitnessPlanEntity;
      context.push(
        ScreenPaths.workoutPlanDetail,
        extra: {
          'storedPlan': storedPlan,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load data on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSavedData();
      }
    });
    
    return MultiBlocListener(
      listeners: [
        BlocListener<NutritionBloc, NutritionState>(
          listenWhen: (previous, current) => current is AllNutritionAnalysesLoaded,
          listener: (context, state) {
            _loadSavedData();
          },
        ),
        BlocListener<FitnessBloc, FitnessState>(
          listenWhen: (previous, current) => current is FitnessLoaded,
          listener: (context, state) {
            _loadSavedData();
          },
        ),
      ],
      child: _buildScaffold(context),
    );
  }
  
  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
            floatingActionButton: _selectedItem != null
                ? FloatingActionButton(
                    onPressed: () {
                      _navigateToDetail(_selectedItem!);
                    },
                    backgroundColor: Colors.blue.shade500,
                    child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  )
                : null,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
              title: Text(
                'Access Your Saved Data',
                style: GoogleFonts.poppins(
          color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: _savedData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No saved data yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Save meals and workout plans to see them here',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 450.0,
                        aspectRatio: 16 / 9,
            viewportFraction: 0.70,
            enlargeCenterPage: true,
            pageSnapping: true,
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
                            _selectedItem = null;
              });
                        },
          ),
                      items: _savedData.map((item) {
            return Builder(
              builder: (BuildContext context) {
                            final isSelected = _selectedItem == item;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                                  if (_selectedItem == item) {
                                    _selectedItem = null;
                      } else {
                                    _selectedItem = item;
                      }
                    });
                  },
                  child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                                  border: isSelected
                                      ? Border.all(color: Colors.blue.shade500, width: 3)
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                        BoxShadow(
                          color: Colors.blue.shade100,
                          blurRadius: 30,
                                            offset: const Offset(0, 10),
                        )
                                        ]
                                      : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 20,
                                            offset: const Offset(0, 5),
                        )
                                        ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                                      // Image section
                          Container(
                                        height: 280,
                                        margin: const EdgeInsets.only(top: 10),
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            // Image
                                            item.imagePath != null &&
                                                    File(item.imagePath!).existsSync()
                                                ? Image.file(
                                                    File(item.imagePath!),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return _buildImagePlaceholder(item.type);
                                                    },
                                                  )
                                                : _buildImagePlaceholder(item.type),
                                            // Type badge
                                            Positioned(
                                              top: 10,
                                              right: 10,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: item.type == SavedItemType.meal
                                                      ? Colors.green.shade600
                                                      : Colors.blue.shade600,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      item.type == SavedItemType.meal
                                                          ? Icons.restaurant
                                                          : Icons.fitness_center,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      item.type == SavedItemType.meal
                                                          ? 'Meal'
                                                          : 'Workout',
                                                      style: GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // Title
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          item.title,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Description
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          item.description,
                                          style: GoogleFonts.poppins(
                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Date
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'Saved on ${DateFormat('MMM dd, yyyy').format(item.createdAt)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
                      }).toList(),
          ),
        ),
      );
    
  }

  Widget _buildImagePlaceholder(SavedItemType type) {
    return Container(
      color: type == SavedItemType.meal
          ? Colors.green.shade100
          : Colors.blue.shade100,
      child: Center(
        child: Icon(
          type == SavedItemType.meal
              ? Icons.restaurant_menu
              : Icons.fitness_center,
          size: 64,
          color: type == SavedItemType.meal
              ? Colors.green.shade400
              : Colors.blue.shade400,
        ),
      ),
    );
  }
}
