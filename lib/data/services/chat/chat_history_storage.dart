import 'dart:convert';
import 'package:fitness/data/models/chat/chat_message_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Helper class to save and load chat history for specific dates
class ChatHistoryStorage {
  static const String _boxName = 'chat_history';
  static Box<Map>? _box;

  static Future<Box<Map>> get _boxInstance async {
    _box ??= await Hive.openBox<Map>(_boxName);
    return _box!;
  }

  /// Get storage key for a specific date and chat context.
  static String _getStorageKey(String userId, DateTime date, {String context = 'chat'}) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${userId}_${context}_$dateStr';
  }

  /// Save chat messages for a specific date and context.
  static Future<void> saveChatHistory(
    String userId,
    DateTime date,
    List<ChatMessageModel> messages, {
    String context = 'chat',
  }) async {
    try {
      final box = await _boxInstance;
      final key = _getStorageKey(userId, date, context: context);
      final messagesJson = messages.map((msg) => msg.toJson()).toList();
      await box.put(key, {
        'userId': userId,
        'date': date.toIso8601String(),
        'messages': messagesJson,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Handle error silently
      print('Error saving chat history: $e');
    }
  }

  /// Load chat messages for a specific date and context.
  static Future<List<ChatMessageModel>> loadChatHistory(
    String userId,
    DateTime date, {
    String context = 'chat',
  }) async {
    try {
      final box = await _boxInstance;
      final key = _getStorageKey(userId, date, context: context);
      final data = box.get(key);
      
      if (data == null) return [];
      
      final messagesJson = data['messages'] as List<dynamic>?;
      if (messagesJson == null) return [];
      
      return messagesJson
          .map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Handle error silently
      print('Error loading chat history: $e');
      return [];
    }
  }

  /// Clear chat history for a specific date and context.
  static Future<void> clearChatHistory(String userId, DateTime date, {String context = 'chat'}) async {
    try {
      final box = await _boxInstance;
      final key = _getStorageKey(userId, date, context: context);
      await box.delete(key);
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }

  /// Initialize the storage box
  static Future<void> init() async {
    await _boxInstance;
  }
}


