import 'package:fitness/app/storage/data/models/stored_fitness_plan_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Data source for local storage using Hive
abstract class LocalStorageDataSource {
  Future<void> init();
  Future<void> saveFitnessPlan(StoredFitnessPlanModel plan);
  Future<List<StoredFitnessPlanModel>> getAllFitnessPlans();
  Future<StoredFitnessPlanModel?> getFitnessPlanById(String id);
  Future<void> deleteFitnessPlan(String id);
  Future<void> updateFitnessPlan(StoredFitnessPlanModel plan);
  Future<List<StoredFitnessPlanModel>> getUnsyncedPlans();
}

class LocalStorageDataSourceImpl implements LocalStorageDataSource {
  static const String _boxName = 'fitness_plans';
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
        // Verify box is open and accessible
        if (!box.isOpen) {
          throw Exception('Failed to open fitness_plans Hive box');
        }
        debugPrint('Fitness plans storage initialized. Existing plans: ${box.keys.length}');
      } catch (e) {
        debugPrint('Error initializing fitness plans storage: $e');
        rethrow;
      }
    }
  }

  @override
  Future<void> saveFitnessPlan(StoredFitnessPlanModel plan) async {
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
        return await saveFitnessPlan(plan); // Retry
      }
      
      debugPrint('Saving fitness plan: ${plan.id}');
      final jsonData = plan.toJson();
      
      // Save to box
      await box.put(plan.id, jsonData);
      
      // Force flush to ensure data is written to disk immediately
      await box.flush();
      
      // Verify data was saved by reading it back
      final saved = box.get(plan.id);
      if (saved == null) {
        throw Exception('Failed to verify saved fitness plan - data not found after save');
      }
      
      debugPrint('Fitness plan saved and verified: ${plan.id}');
    } catch (e, stackTrace) {
      debugPrint('Error saving fitness plan: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<StoredFitnessPlanModel>> getAllFitnessPlans() async {
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
        return await getAllFitnessPlans(); // Retry
      }
      
      debugPrint('Loading fitness plans from Hive box. Box keys count: ${box.keys.length}');
      
      final plans = <StoredFitnessPlanModel>[];
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
            
            final plan = StoredFitnessPlanModel.fromJson(jsonData);
            plans.add(plan);
            debugPrint('Successfully loaded fitness plan: ${plan.id}');
          }
        } catch (e, stackTrace) {
          // Skip invalid entries and log error
          debugPrint('Error loading fitness plan with key $key: $e');
          debugPrint('Stack trace: $stackTrace');
          continue;
        }
      }
      
      debugPrint('Total fitness plans loaded: ${plans.length}');
      
      // Sort by createdAt descending (newest first)
      plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return plans;
    } catch (e, stackTrace) {
      debugPrint('Error in getAllFitnessPlans: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return empty list on error rather than crashing
      return <StoredFitnessPlanModel>[];
    }
  }

  @override
  Future<StoredFitnessPlanModel?> getFitnessPlanById(String id) async {
    final box = await _boxInstance;
    final data = box.get(id);
    if (data == null) return null;
    try {
      return StoredFitnessPlanModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteFitnessPlan(String id) async {
    final box = await _boxInstance;
    await box.delete(id);
    // Ensure deletion is flushed to disk
    await box.flush();
  }

  @override
  Future<void> updateFitnessPlan(StoredFitnessPlanModel plan) async {
    final box = await _boxInstance;
    await box.put(plan.id, plan.toJson());
    // Ensure data is flushed to disk
    await box.flush();
  }

  @override
  Future<List<StoredFitnessPlanModel>> getUnsyncedPlans() async {
    final allPlans = await getAllFitnessPlans();
    return allPlans.where((plan) => !plan.isSynced).toList();
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

  /// Get the storage path where Hive box files are stored
  /// Useful for debugging and understanding where data is persisted
  /// 
  /// On Android: /data/data/YOUR_PACKAGE_NAME/app_flutter/
  /// On iOS: /var/mobile/Containers/Data/Application/.../Documents/
  Future<String> getStoragePath() async {
    try {
      // Hive.initFlutter() sets the storage path
      // The actual path is typically in the app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      return appDir.path;
    } catch (e) {
      debugPrint('Error getting storage path: $e');
      return 'Unknown';
    }
  }

  /// Get the full path to the fitness_plans box file
  /// This is where your workout plan data is actually stored
  Future<String> getBoxFilePath() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      // Hive stores box files with .hive extension
      return '${appDir.path}/$_boxName.hive';
    } catch (e) {
      debugPrint('Error getting box file path: $e');
      return 'Unknown';
    }
  }
}

