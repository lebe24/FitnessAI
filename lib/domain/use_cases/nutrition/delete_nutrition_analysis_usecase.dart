import 'package:fitness/domain/repositories/nutrition_repository.dart';

class DeleteNutritionAnalysisUseCase {
  final NutritionRepository repository;

  DeleteNutritionAnalysisUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteNutritionAnalysis(id);
  }
}
















































