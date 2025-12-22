import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:fitness/app/ui/nutrition/domain/entities/stored_nutrition_analysis_entity.dart';

abstract class NutritionEvent extends Equatable {
  const NutritionEvent();

  @override
  List<Object?> get props => [];
}

class AnalyzeFoodRequested extends NutritionEvent {
  final File image;
  final String? goal;
  final String? gender;
  final String? height;
  final String? weight;
  final String? experience;
  final String? extraInfo;

  const AnalyzeFoodRequested({
    required this.image,
    this.goal,
    this.gender,
    this.height,
    this.weight,
    this.experience,
    this.extraInfo,
  });

  @override
  List<Object?> get props => [image, goal, gender, height, weight, experience, extraInfo];
}

class SaveNutritionAnalysisRequested extends NutritionEvent {
  final StoredNutritionAnalysisEntity analysis;

  const SaveNutritionAnalysisRequested(this.analysis);

  @override
  List<Object?> get props => [analysis];
}

class GetAllNutritionAnalysesRequested extends NutritionEvent {
  const GetAllNutritionAnalysesRequested();
}

class GetNutritionAnalysisByIdRequested extends NutritionEvent {
  final String id;

  const GetNutritionAnalysisByIdRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteNutritionAnalysisRequested extends NutritionEvent {
  final String id;

  const DeleteNutritionAnalysisRequested(this.id);

  @override
  List<Object?> get props => [id];
}






































