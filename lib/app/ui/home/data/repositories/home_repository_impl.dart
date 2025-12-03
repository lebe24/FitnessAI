import 'dart:io';

import 'package:fitness/app/ui/home/data/datasources/home_remote_datasource.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';
import 'package:fitness/app/ui/home/domain/repository/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  HomeRepositoryImpl(this.remoteDataSource);

  @override
  Future<WorkoutPlanEntity> uploadImage(
    String? extrainfo,
    File image, {
    required String goal,
    required String duration,
    required String trainingSplit,
    required String gender,
    required String height,
    required String weight,
    required String experience,
  }) async {
    return await remoteDataSource.uploadImage(
      extrainfo,
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

  @override
  Future<String> getWorkoutPlan() => remoteDataSource.getWorkoutPlan();

  @override
  Future<String> getBaseInfo() => remoteDataSource.getBaseInfo();
}
