import 'package:fitness/domain/models/stored_nutrition_analysis.dart';
import 'package:fitness/domain/repositories/nutrition_repository.dart';

class SaveNutritionAnalysisUseCase {
  final NutritionRepository repository;

  SaveNutritionAnalysisUseCase(this.repository);

  Future<void> call(StoredNutritionAnalysisEntity analysis) {
    return repository.saveNutritionAnalysis(analysis);
  }
}
















































