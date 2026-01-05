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
    // Safely convert workoutPlan
    final workoutPlanData = json['workoutPlan'];
    Map<String, dynamic> workoutPlanJson;
    if (workoutPlanData is Map) {
      workoutPlanJson = workoutPlanData.map((k, v) => MapEntry(
        k.toString(),
        v,
      ));
    } else {
      throw Exception('Invalid workoutPlan data type: ${workoutPlanData.runtimeType}');
    }

    return StoredFitnessPlanModel(
      id: json['id']?.toString() ?? '',
      workoutPlan: WorkoutPlanModel.fromJson(workoutPlanJson),
      imagePath: json['imagePath']?.toString(),
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? DateTime.now().toIso8601String()),
      isSynced: json['isSynced'] == true || json['isSynced'] == 1,
      cloudId: json['cloudId']?.toString(),
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

