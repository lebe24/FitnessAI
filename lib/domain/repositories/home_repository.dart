import 'dart:io';
import 'package:fitness/domain/models/workout_plan.dart';

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
  Future<String> getBaseInfo();
}
