import 'package:equatable/equatable.dart';
import 'package:fitness/app/ui/nutrition/domain/entities/nutrition_analysis_entity.dart';

class StoredNutritionAnalysisEntity extends Equatable {
  final String id;
  final NutritionAnalysisEntity analysis;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StoredNutritionAnalysisEntity({
    required this.id,
    required this.analysis,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, analysis, imagePath, createdAt, updatedAt];
}






























