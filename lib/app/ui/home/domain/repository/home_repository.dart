import 'dart:io';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';

abstract class HomeRepository {
  Future<WorkoutPlanEntity> uploadImage(
    String? extraInfo,
    File image, {
    required String goal,
    required String duration,
    required String trainingSplit,
    required String gender,
    required String height,
    required String weight,
    required String experience,
  });
  Future<String> getWorkoutPlan();
  Future<String> getBaseInfo();
}
