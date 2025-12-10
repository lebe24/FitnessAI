import 'package:fitness/app/ui/nutrition/domain/entities/stored_nutrition_analysis_entity.dart';
import 'package:fitness/app/ui/nutrition/domain/repositories/nutrition_repository.dart';

class GetNutritionAnalysisByIdUseCase {
  final NutritionRepository repository;

  GetNutritionAnalysisByIdUseCase(this.repository);

  Future<StoredNutritionAnalysisEntity?> call(String id) {
    return repository.getNutritionAnalysisById(id);
  }
}
























