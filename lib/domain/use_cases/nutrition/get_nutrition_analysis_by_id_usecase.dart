import 'package:fitness/domain/models/stored_nutrition_analysis.dart';
import 'package:fitness/domain/repositories/nutrition_repository.dart';

class GetNutritionAnalysisByIdUseCase {
  final NutritionRepository repository;

  GetNutritionAnalysisByIdUseCase(this.repository);

  Future<StoredNutritionAnalysisEntity?> call(String id) {
    return repository.getNutritionAnalysisById(id);
  }
}
















































