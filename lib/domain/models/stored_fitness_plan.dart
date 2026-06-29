import 'package:equatable/equatable.dart';
import 'package:fitness/domain/models/workout_plan.dart';

/// Entity representing a stored fitness plan with metadata and image reference
class StoredFitnessPlanEntity extends Equatable {
  final String id;
  final WorkoutPlanEntity workoutPlan;
  final String? imagePath; // Path to the stored image file
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String? cloudId; // ID from cloud storage if synced

  const StoredFitnessPlanEntity({
    required this.id,
    required this.workoutPlan,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.cloudId,
  });

  StoredFitnessPlanEntity copyWith({
    String? id,
    WorkoutPlanEntity? workoutPlan,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? cloudId,
  }) {
    return StoredFitnessPlanEntity(
      id: id ?? this.id,
      workoutPlan: workoutPlan ?? this.workoutPlan,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      cloudId: cloudId ?? this.cloudId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        workoutPlan,
        imagePath,
        createdAt,
        updatedAt,
        isSynced,
        cloudId,
      ];
}

