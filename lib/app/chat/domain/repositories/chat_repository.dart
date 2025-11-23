import 'package:fitness/app/chat/domain/entities/chat_message_entity.dart';
import 'package:fitness/app/chat/domain/entities/chat_response_entity.dart';

/// Repository interface for chat functionality
abstract class ChatRepository {
  /// Connect to the WebSocket chat server
  /// [userName] is the user's name
  /// [workoutPlan] is optional workout plan data to send when connecting
  Future<void> connect(String userId, String userName, {Map<String, dynamic>? workoutPlan});

  /// Disconnect from the WebSocket chat server
  Future<void> disconnect();

  /// Send a message to the chat server
  /// Returns the response from the AI agent
  Future<ChatResponseEntity> sendMessage({
    required String message,
    required String userId,
  });

  /// Stream of incoming messages from the server
  Stream<ChatMessageEntity> get messageStream;

  /// Check if the connection is active
  bool get isConnected;
}

