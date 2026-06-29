import 'dart:async';
import 'dart:convert';
import 'package:fitness/data/models/chat/chat_message_model.dart';
import 'package:fitness/data/models/chat/chat_response_model.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class ChatRemoteDataSource {
  Future<void> connect(String userId, String userName, {Map<String, dynamic>? workoutPlan});
  Future<void> disconnect();
  Future<ChatResponseModel> sendMessage({required String message, required String userId});
  Stream<ChatMessageModel> get messageStream;
  bool get isConnected;
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _messageController = StreamController<ChatMessageModel>.broadcast();
  bool _isConnected = false;
  String _currentUserId = '';

  @override
  Future<void> connect(String userId, String userName, {Map<String, dynamic>? workoutPlan}) async {
    if (_isConnected && _channel != null) return;

    _currentUserId = userId;

    final uri = Uri.parse('${Constant.chatWsUrl}?userId=$userId');
    _channel = WebSocketChannel.connect(uri);

    // Await the TLS + WebSocket handshake — throws if the server refuses.
    await _channel!.ready;
    _isConnected = true;

    // Send session context immediately after handshake.
    _channel!.sink.add(jsonEncode({
      'type': 'connection',
      'userId': userId,
      'userName': userName,
      if (workoutPlan != null) 'workoutPlan': workoutPlan,
    }));

    _subscription = _channel!.stream.listen(
      _onData,
      onError: (error) {
        _isConnected = false;
        _messageController.addError(error);
      },
      onDone: () {
        _isConnected = false;
      },
      cancelOnError: false,
    );
  }

  void _onData(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;

      // Typing indicator — not a message, ignore.
      if (json['type'] == 'typing') return;

      // Server-side error — surface via stream error.
      if (json['type'] == 'error') {
        _messageController.addError(
          Exception(json['content'] ?? json['message'] ?? 'Unknown server error'),
        );
        return;
      }

      // Connection acknowledgement — not a chat message.
      if (json['type'] == 'connection_ack') return;

      // Everything else is a chat message from the assistant.
      if (json['type'] == 'message' ||
          json.containsKey('message') ||
          json.containsKey('content')) {
        final msg = ChatMessageModel.fromJson(json);
        if (!msg.isFromUser) _messageController.add(msg);
      }
    } catch (_) {
      // Non-JSON frame — treat as raw assistant text.
      _messageController.add(ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: data.toString(),
        userId: _currentUserId,
        timestamp: DateTime.now(),
        isFromUser: false,
      ));
    }
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
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
    _channel!.sink.add(jsonEncode({'message': message}));
    // Response arrives asynchronously via messageStream.
    return ChatResponseModel(message: '', planUpdated: false, updatedPlanData: null);
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

