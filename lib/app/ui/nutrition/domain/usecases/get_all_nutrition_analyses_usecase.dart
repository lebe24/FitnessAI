import 'package:fitness/app/ui/nutrition/domain/entities/stored_nutrition_analysis_entity.dart';
import 'package:fitness/app/ui/nutrition/domain/repositories/nutrition_repository.dart';

class GetAllNutritionAnalysesUseCase {
  final NutritionRepository repository;

  GetAllNutritionAnalysesUseCase(this.repository);

  Future<List<StoredNutritionAnalysisEntity>> call() {
    return repository.getAllNutritionAnalyses();
  }
}




































