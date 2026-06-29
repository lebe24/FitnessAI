import 'package:fitness/data/services/fitness/body_composition_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BodyScanStorage {
  static const _boxName = 'body_scans';

  Box<Map>? _box;

  static Future<void> init() async {
    await Hive.openBox<Map>(_boxName);
  }

  Future<Box<Map>> _open() async {
    _box ??= await Hive.openBox<Map>(_boxName);
    return _box!;
  }

  Future<void> save(BodyCompositionResult result, String imagePath) async {
    final box = await _open();
    final entry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'imagePath': imagePath,
      'data': result.rawJson,
    };
    await box.add(Map<String, dynamic>.from(entry));
  }

  Future<List<Map>> getAll() async {
    final box = await _open();
    return box.values.toList().reversed.toList();
  }

  Future<void> delete(int key) async {
    final box = await _open();
    await box.delete(key);
  }

  Future<void> clear() async {
    final box = await _open();
    await box.clear();
  }
}
