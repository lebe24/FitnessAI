import 'dart:io';
import 'package:fitness/app/ui/nutrition/data/datasources/nutrition_local_datasource.dart';
import 'package:fitness/app/ui/nutrition/data/datasources/nutrition_remote_datasource.dart';
import 'package:fitness/app/ui/nutrition/data/models/nutrition_analysis_model.dart';
import 'package:fitness/app/ui/nutrition/data/models/stored_nutrition_analysis_model.dart';
import 'package:fitness/app/ui/nutrition/domain/entities/nutrition_analysis_entity.dart';
import 'package:fitness/app/ui/nutrition/domain/entities/stored_nutrition_analysis_entity.dart';
import 'package:fitness/app/ui/nutrition/domain/repositories/nutrition_repository.dart';

class NutritionRepositoryImpl implements NutritionRepository {
  final NutritionRemoteDataSource remoteDataSource;
  final NutritionLocalDataSource localDataSource;

  NutritionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<NutritionAnalysisEntity> analyzeFood({
    required File image,
    String? goal,
    String? gender,
    String? height,
    String? weight,
    String? experience,
    String? extraInfo,
  }) async {
    final model = await remoteDataSource.analyzeFood(
      image: image,
      goal: goal,
      gender: gender,
      height: height,
      weight: weight,
      experience: experience,
      extraInfo: extraInfo,
    );
    return model;
  }

  @override
  Future<void> saveNutritionAnalysis(StoredNutritionAnalysisEntity analysis) async {
    final model = StoredNutritionAnalysisModel.fromEntity(analysis);
    await localDataSource.saveNutritionAnalysis(model);
  }

  @override
  Future<List<StoredNutritionAnalysisEntity>> getAllNutritionAnalyses() async {
    final models = await localDataSource.getAllNutritionAnalyses();
    return models;
  }

  @override
  Future<StoredNutritionAnalysisEntity?> getNutritionAnalysisById(String id) async {
    final model = await localDataSource.getNutritionAnalysisById(id);
    return model;
  }

  @override
  Future<void> deleteNutritionAnalysis(String id) async {
    await localDataSource.deleteNutritionAnalysis(id);
  }
}











