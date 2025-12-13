import 'package:fitness/app/ui/nutrition/data/models/stored_nutrition_analysis_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class NutritionLocalDataSource {
  Future<void> init();
  Future<void> saveNutritionAnalysis(StoredNutritionAnalysisModel analysis);
  Future<List<StoredNutritionAnalysisModel>> getAllNutritionAnalyses();
  Future<StoredNutritionAnalysisModel?> getNutritionAnalysisById(String id);
  Future<void> deleteNutritionAnalysis(String id);
}

class NutritionLocalDataSourceImpl implements NutritionLocalDataSource {
  static const String _boxName = 'nutrition_analyses';
  Box<Map>? _box;

  Future<Box<Map>> get _boxInstance async {
    _box ??= await Hive.openBox<Map>(_boxName);
    return _box!;
  }

  @override
  Future<void> init() async {
    await _boxInstance;
  }

  @override
  Future<void> saveNutritionAnalysis(StoredNutritionAnalysisModel analysis) async {
    final box = await _boxInstance;
    await box.put(analysis.id, analysis.toJson());
  }

  @override
  Future<List<StoredNutritionAnalysisModel>> getAllNutritionAnalyses() async {
    final box = await _boxInstance;
    final analyses = <StoredNutritionAnalysisModel>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        try {
          analyses.add(StoredNutritionAnalysisModel.fromJson(Map<String, dynamic>.from(data)));
        } catch (e) {
          continue;
        }
      }
    }
    analyses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return analyses;
  }

  @override
  Future<StoredNutritionAnalysisModel?> getNutritionAnalysisById(String id) async {
    final box = await _boxInstance;
    final data = box.get(id);
    if (data == null) return null;
    try {
      return StoredNutritionAnalysisModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteNutritionAnalysis(String id) async {
    final box = await _boxInstance;
    await box.delete(id);
  }
}






























