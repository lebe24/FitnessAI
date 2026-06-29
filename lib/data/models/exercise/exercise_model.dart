import 'package:fitness/domain/models/exercise.dart';

/// Model representing an exercise from ExerciseDB API
class ExerciseModel extends ExerciseEntity {
  const ExerciseModel({
    required super.id,
    required super.name,
    super.description,
    required super.primaryMuscles,
    required super.secondaryMuscles,
    required super.instructions,
    super.equipment,
    super.bodyPart,
    super.gifUrl,
    super.imageUrl,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      primaryMuscles: json['primaryMuscles'] != null
          ? List<String>.from(json['primaryMuscles'] as List)
          : json['primaryMuscle'] != null
              ? [json['primaryMuscle'] as String]
              : [],
      secondaryMuscles: json['secondaryMuscles'] != null
          ? List<String>.from(json['secondaryMuscles'] as List)
          : json['secondaryMuscle'] != null
              ? [json['secondaryMuscle'] as String]
              : [],
      instructions: json['instructions'] != null
          ? List<String>.from(json['instructions'] as List)
          : json['instruction'] != null
              ? [json['instruction'] as String]
              : [],
      equipment: json['equipment'] as String?,
      bodyPart: json['bodyPart'] as String? ?? json['bodypart'] as String?,
      gifUrl: json['gifUrl'] as String? ?? json['gif'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'primaryMuscles': primaryMuscles,
      'secondaryMuscles': secondaryMuscles,
      'instructions': instructions,
      if (equipment != null) 'equipment': equipment,
      if (bodyPart != null) 'bodyPart': bodyPart,
      if (gifUrl != null) 'gifUrl': gifUrl,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

/// Model representing an exercise search result
class ExerciseSearchResultModel extends ExerciseSearchResultEntity {
  const ExerciseSearchResultModel({
    required super.id,
    required super.name,
    super.bodyPart,
    super.equipment,
    super.gifUrl,
  });

  factory ExerciseSearchResultModel.fromJson(Map<String, dynamic> json) {
    return ExerciseSearchResultModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      bodyPart: json['bodyPart'] as String? ?? json['bodypart'] as String?,
      equipment: json['equipment'] as String?,
      gifUrl: json['gifUrl'] as String? ?? json['gif'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (bodyPart != null) 'bodyPart': bodyPart,
      if (equipment != null) 'equipment': equipment,
      if (gifUrl != null) 'gifUrl': gifUrl,
    };
  }
}

