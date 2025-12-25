import 'package:fitness/app/ui/nutrition/domain/entities/stored_nutrition_analysis_entity.dart';
import 'package:fitness/app/ui/nutrition/domain/repositories/nutrition_repository.dart';

class SaveNutritionAnalysisUseCase {
  final NutritionRepository repository;

  SaveNutritionAnalysisUseCase(this.repository);

  Future<void> call(StoredNutritionAnalysisEntity analysis) {
    return repository.saveNutritionAnalysis(analysis);
  }
}











































