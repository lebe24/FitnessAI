import 'package:fitness/app/chat/data/helpers/chat_history_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Initialize storage system (Hive)
/// This should be called before using any storage functionality
Future<void> initializeStorage() async {
  await Hive.initFlutter();
  // Initialize chat history storage
  await ChatHistoryStorage.init();
}

