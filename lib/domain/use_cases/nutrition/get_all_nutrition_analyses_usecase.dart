import 'package:fitness/domain/models/stored_nutrition_analysis.dart';
import 'package:fitness/domain/repositories/nutrition_repository.dart';

class GetAllNutritionAnalysesUseCase {
  final NutritionRepository repository;

  GetAllNutritionAnalysesUseCase(this.repository);

  Future<List<StoredNutritionAnalysisEntity>> call() {
    return repository.getAllNutritionAnalyses();
  }
}
















































