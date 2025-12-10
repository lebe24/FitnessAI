import 'package:equatable/equatable.dart';
import 'package:fitness/app/ui/nutrition/domain/entities/nutrition_analysis_entity.dart';
import 'package:fitness/app/ui/nutrition/domain/entities/stored_nutrition_analysis_entity.dart';

abstract class NutritionState extends Equatable {
  const NutritionState();

  @override
  List<Object?> get props => [];
}

class NutritionInitial extends NutritionState {}

class NutritionLoading extends NutritionState {}

class NutritionAnalysisLoaded extends NutritionState {
  final NutritionAnalysisEntity analysis;
  final String? imagePath;

  const NutritionAnalysisLoaded({
    required this.analysis,
    this.imagePath,
  });

  @override
  List<Object?> get props => [analysis, imagePath];
}

class NutritionAnalysisSaved extends NutritionState {
  const NutritionAnalysisSaved();
}

class AllNutritionAnalysesLoaded extends NutritionState {
  final List<StoredNutritionAnalysisEntity> analyses;

  const AllNutritionAnalysesLoaded(this.analyses);

  @override
  List<Object?> get props => [analyses];
}

class NutritionError extends NutritionState {
  final String message;

  const NutritionError(this.message);

  @override
  List<Object?> get props => [message];
}
























