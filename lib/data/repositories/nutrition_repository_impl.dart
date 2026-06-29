import 'dart:io';
import 'package:fitness/data/services/nutrition/nutrition_local_service.dart';
import 'package:fitness/data/services/nutrition/nutrition_remote_service.dart';
import 'package:fitness/data/models/nutrition/nutrition_analysis_model.dart';
import 'package:fitness/data/models/nutrition/stored_nutrition_analysis_model.dart';
import 'package:fitness/domain/models/nutrition_analysis.dart';
import 'package:fitness/domain/models/stored_nutrition_analysis.dart';
import 'package:fitness/domain/repositories/nutrition_repository.dart';

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
















































