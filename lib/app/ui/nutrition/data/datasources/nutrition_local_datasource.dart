import 'package:fitness/app/ui/nutrition/data/models/stored_nutrition_analysis_model.dart';
import 'package:flutter/foundation.dart';
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
  bool _isInitialized = false;

  Future<Box<Map>> get _boxInstance async {
    if (_box == null || !_box!.isOpen) {
      try {
        _box = await Hive.openBox<Map>(_boxName);
        _isInitialized = true;
        debugPrint('Hive box "$_boxName" opened successfully. Keys: ${_box!.keys.length}');
      } catch (e) {
        debugPrint('Error opening Hive box "$_boxName": $e');
        rethrow;
      }
    }
    return _box!;
  }

  @override
  Future<void> init() async {
    if (!_isInitialized) {
      try {
        final box = await _boxInstance;
        if (!box.isOpen) {
          throw Exception('Failed to open nutrition_analyses Hive box');
        }
        debugPrint('Nutrition analyses storage initialized. Existing analyses: ${box.keys.length}');
      } catch (e) {
        debugPrint('Error initializing nutrition analyses storage: $e');
        rethrow;
      }
    }
  }

  @override
  Future<void> saveNutritionAnalysis(StoredNutritionAnalysisModel analysis) async {
    try {
      // Ensure box is initialized
      if (!_isInitialized) {
        await init();
      }
      
      final box = await _boxInstance;
      if (!box.isOpen) {
        // Reopen box if it was closed
        _box = null;
        _isInitialized = false;
        await init();
        return await saveNutritionAnalysis(analysis); // Retry
      }
      
      debugPrint('Saving nutrition analysis: ${analysis.id}');
      final jsonData = analysis.toJson();
      
      // Save to box
      await box.put(analysis.id, jsonData);
      
      // Force flush to ensure data is written to disk immediately
      await box.flush();
      
      // Verify data was saved by reading it back
      final saved = box.get(analysis.id);
      if (saved == null) {
        throw Exception('Failed to verify saved nutrition analysis - data not found after save');
      }
      
      debugPrint('Nutrition analysis saved and verified: ${analysis.id}');
    } catch (e, stackTrace) {
      debugPrint('Error saving nutrition analysis: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<StoredNutritionAnalysisModel>> getAllNutritionAnalyses() async {
    try {
      // Ensure box is initialized
      if (!_isInitialized) {
        await init();
      }
      
      final box = await _boxInstance;
      if (!box.isOpen) {
        // Reopen box if it was closed
        _box = null;
        _isInitialized = false;
        await init();
        return await getAllNutritionAnalyses(); // Retry
      }
      
      debugPrint('Loading nutrition analyses from Hive box. Box keys count: ${box.keys.length}');
      
      final analyses = <StoredNutritionAnalysisModel>[];
      for (var key in box.keys) {
        try {
          final data = box.get(key);
          if (data != null) {
            // Convert Hive's Map<dynamic, dynamic> to Map<String, dynamic>
            Map<String, dynamic> jsonData;
            if (data is Map) {
              jsonData = data.map((k, v) => MapEntry(
                k.toString(),
                v is Map ? _convertMap(v) : v,
              ));
            } else {
              debugPrint('Invalid data type for key $key: ${data.runtimeType}');
              continue;
            }
            
            final analysis = StoredNutritionAnalysisModel.fromJson(jsonData);
            analyses.add(analysis);
            debugPrint('Successfully loaded nutrition analysis: ${analysis.id}');
          }
        } catch (e, stackTrace) {
          // Skip invalid entries and log error
          debugPrint('Error loading nutrition analysis with key $key: $e');
          debugPrint('Stack trace: $stackTrace');
          continue;
        }
      }
      
      debugPrint('Total nutrition analyses loaded: ${analyses.length}');
      
      // Sort by createdAt descending (newest first)
      analyses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return analyses;
    } catch (e, stackTrace) {
      debugPrint('Error in getAllNutritionAnalyses: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return empty list on error rather than crashing
      return <StoredNutritionAnalysisModel>[];
    }
  }

  /// Recursively convert nested Maps from dynamic types to String keys
  dynamic _convertMap(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(
        k.toString(),
        _convertMap(v),
      ));
    } else if (value is List) {
      return value.map((item) => _convertMap(item)).toList();
    }
    return value;
  }

  @override
  Future<StoredNutritionAnalysisModel?> getNutritionAnalysisById(String id) async {
    try {
      final box = await _boxInstance;
      if (!box.isOpen) {
        _box = null;
        _isInitialized = false;
        await init();
        return await getNutritionAnalysisById(id); // Retry
      }
      
      final data = box.get(id);
      if (data == null) return null;
      
      // Convert Hive's Map<dynamic, dynamic> to Map<String, dynamic>
      Map<String, dynamic> jsonData;
      if (data is Map) {
        jsonData = data.map((k, v) => MapEntry(
          k.toString(),
          v is Map ? _convertMap(v) : v,
        ));
      } else {
        debugPrint('Invalid data type for nutrition analysis $id: ${data.runtimeType}');
        return null;
      }
      
      return StoredNutritionAnalysisModel.fromJson(jsonData);
    } catch (e, stackTrace) {
      debugPrint('Error loading nutrition analysis by id $id: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  @override
  Future<void> deleteNutritionAnalysis(String id) async {
    try {
      final box = await _boxInstance;
      if (!box.isOpen) {
        _box = null;
        _isInitialized = false;
        await init();
        return await deleteNutritionAnalysis(id); // Retry
      }
      
      await box.delete(id);
      // Ensure deletion is flushed to disk
      await box.flush();
      debugPrint('Nutrition analysis deleted: $id');
    } catch (e) {
      debugPrint('Error deleting nutrition analysis $id: $e');
      rethrow;
    }
  }
}
















































