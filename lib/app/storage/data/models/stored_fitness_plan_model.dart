import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/ui/home/data/model/workout_plan_model.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';

/// Model for stored fitness plan with JSON serialization
class StoredFitnessPlanModel extends StoredFitnessPlanEntity {
  const StoredFitnessPlanModel({
    required super.id,
    required super.workoutPlan,
    super.imagePath,
    required super.createdAt,
    required super.updatedAt,
    required super.isSynced,
    super.cloudId,
  });

  factory StoredFitnessPlanModel.fromEntity(StoredFitnessPlanEntity entity) {
    return StoredFitnessPlanModel(
      id: entity.id,
      workoutPlan: entity.workoutPlan,
      imagePath: entity.imagePath,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: entity.isSynced,
      cloudId: entity.cloudId,
    );
  }

  factory StoredFitnessPlanModel.fromJson(Map<String, dynamic> json) {
    return StoredFitnessPlanModel(
      id: json['id'] as String,
      workoutPlan: WorkoutPlanModel.fromJson(
        json['workoutPlan'] as Map<String, dynamic>,
      ),
      imagePath: json['imagePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      cloudId: json['cloudId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutPlan': (workoutPlan as WorkoutPlanModel).toJson(),
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
      'cloudId': cloudId,
    };
  }

  StoredFitnessPlanModel copyWith({
    String? id,
    WorkoutPlanEntity? workoutPlan,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? cloudId,
  }) {
    return StoredFitnessPlanModel(
      id: id ?? this.id,
      workoutPlan: workoutPlan ?? this.workoutPlan,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      cloudId: cloudId ?? this.cloudId,
    );
  }
}

