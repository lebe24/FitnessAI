import 'dart:io';
import 'package:fitness/domain/models/nutrition_analysis.dart';
import 'package:fitness/domain/models/stored_nutrition_analysis.dart';

abstract class NutritionRepository {
  Future<NutritionAnalysisEntity> analyzeFood({
    required File image,
    String? goal,
    String? gender,
    String? height,
    String? weight,
    String? experience,
    String? extraInfo,
  });

  Future<void> saveNutritionAnalysis(StoredNutritionAnalysisEntity analysis);
  Future<List<StoredNutritionAnalysisEntity>> getAllNutritionAnalyses();
  Future<StoredNutritionAnalysisEntity?> getNutritionAnalysisById(String id);
  Future<void> deleteNutritionAnalysis(String id);
}
















































