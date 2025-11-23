import 'dart:async';
import 'dart:convert';
import 'package:fitness/app/chat/data/models/chat_message_model.dart';
import 'package:fitness/app/chat/data/models/chat_response_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Data source interface for chat WebSocket communication
abstract class ChatRemoteDataSource {
  /// Connect to the WebSocket server
  /// [userName] is the user's name
  /// [workoutPlan] is optional workout plan data to send when connecting
  Future<void> connect(String userId, String userName, {Map<String, dynamic>? workoutPlan});

  /// Disconnect from the WebSocket server
  Future<void> disconnect();

  /// Send a message to the server
  Future<ChatResponseModel> sendMessage({
    required String message,
    required String userId,
  });

  /// Stream of incoming messages
  Stream<ChatMessageModel> get messageStream;

  /// Check if connected
  bool get isConnected;
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  static const String _baseUrl = 'ws://fwq1p840-8080.uks1.devtunnels.ms/ws/chat';
  
  WebSocketChannel? _channel;
  final _messageController = StreamController<ChatMessageModel>.broadcast();
  bool _isConnected = false;

  @override
  Future<void> connect(String userId, String userName, {Map<String, dynamic>? workoutPlan}) async {
    if (_isConnected && _channel != null) {
      return;
    }

    try {
      final uri = Uri.parse('$_baseUrl?userId=$userId');
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      // Wait for connection to be established before sending user info and workout plan
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Send user info and workout plan data if provided
      if (_channel != null) {
        final connectionMessage = {
          'type': 'connection',
          'userId': userId,
          'userName': userName,
          if (workoutPlan != null) 'workoutPlan': workoutPlan,
        };
        _channel!.sink.add(jsonEncode(connectionMessage));
      }

      // Listen to incoming messages
      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String);
            
            // Handle different message types from backend
            if (json is Map<String, dynamic>) {
              // Check if it's an error message
              if (json['type'] == 'error') {
                // Handle error - don't add as message, let the error handler deal with it
                _messageController.addError(Exception(json['content'] ?? json['message'] ?? 'Unknown error'));
                return;
              }
              
              // Only add messages (not typing indicators or other types)
              if (json['type'] == 'message' || json.containsKey('message') || json.containsKey('content')) {
                final message = ChatMessageModel.fromJson(json);
                // Only add assistant messages from stream (user messages are added immediately when sending)
                // This prevents duplicate user messages
                if (!message.isFromUser) {
                  _messageController.add(message);
                }
              }
            } else {
              // Handle plain string messages
              final message = ChatMessageModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                message: data.toString(),
                userId: userId,
                timestamp: DateTime.now(),
                isFromUser: false,
              );
              _messageController.add(message);
            }
          } catch (e) {
            // Handle non-JSON messages or errors
            final message = ChatMessageModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              message: data.toString(),
              userId: userId,
              timestamp: DateTime.now(),
              isFromUser: false,
            );
            _messageController.add(message);
          }
        },
        onError: (error) {
          _isConnected = false;
          _messageController.addError(error);
        },
        onDone: () {
          _isConnected = false;
        },
        cancelOnError: false,
      );
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  @override
  Future<ChatResponseModel> sendMessage({
    required String message,
    required String userId,
  }) async {
    if (!_isConnected || _channel == null) {
      throw Exception('Not connected to chat server');
    }

    try {
      // Send message to server (matching HTML implementation)
      // Just send the message, don't wait for response
      // The response will come through the message stream
      final messageData = {
        'message': message,
      };

      _channel!.sink.add(jsonEncode(messageData));

      // Return immediately - response will come through messageStream
      // This matches the HTML implementation where they just send and handle responses via onmessage
      return ChatResponseModel(
        message: '', // Empty, actual response comes through stream
        planUpdated: false,
        updatedPlanData: null,
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Stream<ChatMessageModel> get messageStream => _messageController.stream;

  @override
  bool get isConnected => _isConnected;

  void dispose() {
    _messageController.close();
    disconnect();
  }
}

