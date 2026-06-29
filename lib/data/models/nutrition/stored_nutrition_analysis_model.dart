import 'package:fitness/domain/models/nutrition_analysis.dart';
import 'package:fitness/domain/models/stored_nutrition_analysis.dart';
import 'package:fitness/data/models/nutrition/nutrition_analysis_model.dart';

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
    // Safely convert analysis
    final analysisData = json['analysis'];
    Map<String, dynamic> analysisJson;
    if (analysisData is Map) {
      analysisJson = analysisData.map((k, v) => MapEntry(
        k.toString(),
        v,
      ));
    } else {
      throw Exception('Invalid analysis data type: ${analysisData.runtimeType}');
    }

    return StoredNutritionAnalysisModel(
      id: json['id']?.toString() ?? '',
      analysis: NutritionAnalysisModel.fromJson(analysisJson),
      imagePath: json['imagePath']?.toString(),
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? DateTime.now().toIso8601String()),
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
















































