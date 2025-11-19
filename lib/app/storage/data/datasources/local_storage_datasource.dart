import 'package:fitness/app/storage/data/models/stored_fitness_plan_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  Future<Box<Map>> get _boxInstance async {
    _box ??= await Hive.openBox<Map>(_boxName);
    return _box!;
  }

  @override
  Future<void> init() async {
    await _boxInstance;
  }

  @override
  Future<void> saveFitnessPlan(StoredFitnessPlanModel plan) async {
    final box = await _boxInstance;
    await box.put(plan.id, plan.toJson());
  }

  @override
  Future<List<StoredFitnessPlanModel>> getAllFitnessPlans() async {
    final box = await _boxInstance;
    final plans = <StoredFitnessPlanModel>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        try {
          plans.add(StoredFitnessPlanModel.fromJson(Map<String, dynamic>.from(data)));
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }
    }
    // Sort by createdAt descending (newest first)
    plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return plans;
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
  }

  @override
  Future<void> updateFitnessPlan(StoredFitnessPlanModel plan) async {
    final box = await _boxInstance;
    await box.put(plan.id, plan.toJson());
  }

  @override
  Future<List<StoredFitnessPlanModel>> getUnsyncedPlans() async {
    final allPlans = await getAllFitnessPlans();
    return allPlans.where((plan) => !plan.isSynced).toList();
  }
}

