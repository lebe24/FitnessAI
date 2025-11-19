import 'package:hive_flutter/hive_flutter.dart';

/// Initialize storage system (Hive)
/// This should be called before using any storage functionality
Future<void> initializeStorage() async {
  await Hive.initFlutter();
}

