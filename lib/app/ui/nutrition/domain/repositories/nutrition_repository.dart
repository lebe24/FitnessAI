import 'dart:io';
import 'package:fitness/app/ui/nutrition/domain/entities/nutrition_analysis_entity.dart';
import 'package:fitness/app/ui/nutrition/domain/entities/stored_nutrition_analysis_entity.dart';

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
















































