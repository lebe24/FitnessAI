import 'dart:io';
import 'package:fitness/domain/models/nutrition_analysis.dart';
import 'package:fitness/domain/repositories/nutrition_repository.dart';

class AnalyzeFoodUseCase {
  final NutritionRepository repository;

  AnalyzeFoodUseCase(this.repository);

  Future<NutritionAnalysisEntity> call({
    required File image,
    String? goal,
    String? gender,
    String? height,
    String? weight,
    String? experience,
    String? extraInfo,
  }) {
    return repository.analyzeFood(
      image: image,
      goal: goal,
      gender: gender,
      height: height,
      weight: weight,
      experience: experience,
      extraInfo: extraInfo,
    );
  }
}
















































