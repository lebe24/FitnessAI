import 'package:fitness/app/ui/nutrition/domain/entities/nutrition_analysis_entity.dart';
import 'package:fitness/app/ui/nutrition/domain/entities/stored_nutrition_analysis_entity.dart';
import 'package:fitness/app/ui/nutrition/data/models/nutrition_analysis_model.dart';

class StoredNutritionAnalysisModel extends StoredNutritionAnalysisEntity {
  const StoredNutritionAnalysisModel({
    required super.id,
    required super.analysis,
    super.imagePath,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StoredNutritionAnalysisModel.fromEntity(StoredNutritionAnalysisEntity entity) {
    return StoredNutritionAnalysisModel(
      id: entity.id,
      analysis: entity.analysis,
      imagePath: entity.imagePath,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory StoredNutritionAnalysisModel.fromJson(Map<String, dynamic> json) {
    return StoredNutritionAnalysisModel(
      id: json['id'] as String,
      analysis: NutritionAnalysisModel.fromJson(json['analysis'] as Map<String, dynamic>),
      imagePath: json['imagePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'analysis': (analysis as NutritionAnalysisModel).toJson(),
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  StoredNutritionAnalysisModel copyWith({
    String? id,
    NutritionAnalysisEntity? analysis,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoredNutritionAnalysisModel(
      id: id ?? this.id,
      analysis: analysis ?? this.analysis,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}











































