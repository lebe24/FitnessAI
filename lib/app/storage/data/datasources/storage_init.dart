import 'package:fitness/app/chat/data/helpers/chat_history_storage.dart';
import 'package:fitness/app/ui/nutrition/data/datasources/nutrition_local_datasource.dart';
import 'package:fitness/app/storage/data/datasources/local_storage_datasource.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Initialize storage system (Hive)
/// This should be called before using any storage functionality
Future<void> initializeStorage() async {
  await Hive.initFlutter();
  // Initialize chat history storage
  await ChatHistoryStorage.init();
  // Initialize nutrition local storage
  await NutritionLocalDataSourceImpl().init();
  // Initialize fitness plans local storage
  await LocalStorageDataSourceImpl().init();
  // Initialize completed workout dates box (used by FitnessBloc)
  await Hive.openBox('completed_workout_dates');
  // Initialize nutrition analyses box explicitly to ensure it's open
  await Hive.openBox<Map>('nutrition_analyses');
}

