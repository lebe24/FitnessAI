import 'dart:io';
import 'package:fitness/domain/models/nutrition_analysis.dart';
import 'package:fitness/domain/models/stored_nutrition_analysis.dart';
import 'package:fitness/domain/use_cases/nutrition/analyze_food_usecase.dart';
import 'package:fitness/domain/use_cases/nutrition/delete_nutrition_analysis_usecase.dart';
import 'package:fitness/domain/use_cases/nutrition/get_all_nutrition_analyses_usecase.dart';
import 'package:fitness/domain/use_cases/nutrition/get_nutrition_analysis_by_id_usecase.dart';
import 'package:fitness/domain/use_cases/nutrition/save_nutrition_analysis_usecase.dart';
import 'package:flutter/foundation.dart';

class NutritionViewModel extends ChangeNotifier {
  final AnalyzeFoodUseCase _analyzeFoodUseCase;
  final SaveNutritionAnalysisUseCase _saveNutritionAnalysisUseCase;
  final GetAllNutritionAnalysesUseCase _getAllNutritionAnalysesUseCase;
  final GetNutritionAnalysisByIdUseCase _getNutritionAnalysisByIdUseCase;
  final DeleteNutritionAnalysisUseCase _deleteNutritionAnalysisUseCase;

  NutritionViewModel({
    required AnalyzeFoodUseCase analyzeFoodUseCase,
    required SaveNutritionAnalysisUseCase saveNutritionAnalysisUseCase,
    required GetAllNutritionAnalysesUseCase getAllNutritionAnalysesUseCase,
    required GetNutritionAnalysisByIdUseCase getNutritionAnalysisByIdUseCase,
    required DeleteNutritionAnalysisUseCase deleteNutritionAnalysisUseCase,
  })  : _analyzeFoodUseCase = analyzeFoodUseCase,
        _saveNutritionAnalysisUseCase = saveNutritionAnalysisUseCase,
        _getAllNutritionAnalysesUseCase = getAllNutritionAnalysesUseCase,
        _getNutritionAnalysisByIdUseCase = getNutritionAnalysisByIdUseCase,
        _deleteNutritionAnalysisUseCase = deleteNutritionAnalysisUseCase;

  NutritionAnalysisEntity? _analysis;
  String? _imagePath;
  List<StoredNutritionAnalysisEntity> _analyses = [];
  bool _isLoading = false;
  bool _isSaved = false;
  String? _error;

  NutritionAnalysisEntity? get analysis => _analysis;
  String? get imagePath => _imagePath;
  List<StoredNutritionAnalysisEntity> get analyses => _analyses;
  bool get isLoading => _isLoading;
  bool get isSaved => _isSaved;
  String? get error => _error;

  Future<void> analyzeFood({
    required File image,
    String? goal,
    String? gender,
    String? height,
    String? weight,
    String? experience,
    String? extraInfo,
  }) async {
    _isLoading = true;
    _error = null;
    _isSaved = false;
    notifyListeners();
    try {
      _analysis = await _analyzeFoodUseCase(
        image: image,
        goal: goal,
        gender: gender,
        height: height,
        weight: weight,
        experience: experience,
        extraInfo: extraInfo,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveAnalysis(StoredNutritionAnalysisEntity storedAnalysis) async {
    try {
      await _saveNutritionAnalysisUseCase(storedAnalysis);
      _isSaved = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadAllAnalyses() async {
    try {
      _analyses = await _getAllNutritionAnalysesUseCase();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadAnalysisById(String id) async {
    try {
      final stored = await _getNutritionAnalysisByIdUseCase(id);
      if (stored != null) {
        _analysis = stored.analysis;
        _imagePath = stored.imagePath;
      } else {
        _error = 'Analysis not found';
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteAnalysis(String id) async {
    try {
      await _deleteNutritionAnalysisUseCase(id);
      _analyses = await _getAllNutritionAnalysesUseCase();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setImagePath(String? path) {
    _imagePath = path;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
