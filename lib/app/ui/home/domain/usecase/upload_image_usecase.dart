import 'dart:io';

import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';
import 'package:fitness/app/ui/home/domain/repository/home_repository.dart';

class UploadImageUseCase {
  final HomeRepository repository;
  UploadImageUseCase(this.repository);

  Future<WorkoutPlanEntity> uploadImage(
    File image, {
    String? extraInfo,
    required String goal,
    required String duration,
    required String trainingSplit,
    required String gender,
    required String height,
    required String weight,
    required String experience,
  }) async {
    return await repository.uploadImage(
      extraInfo,
      image,
      goal: goal,
      duration: duration,
      trainingSplit: trainingSplit,
      gender: gender,
      height: height,
      weight: weight,
      experience: experience,
    );
  }
}
