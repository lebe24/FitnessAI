import 'dart:async';
import 'package:fitness/data/models/chat/chat_message_model.dart';
import 'package:fitness/data/services/chat/chat_history_storage.dart';
import 'package:fitness/domain/models/chat_message.dart';
import 'package:fitness/domain/repositories/chat_repository.dart';
import 'package:fitness/domain/use_cases/chat/connect_chat_usecase.dart';
import 'package:fitness/domain/use_cases/chat/disconnect_chat_usecase.dart';
import 'package:fitness/domain/use_cases/chat/send_message_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class ChatViewModel extends ChangeNotifier {
  final ConnectChatUsecase _connectChatUsecase;
  final DisconnectChatUsecase _disconnectChatUsecase;
  final SendMessageUsecase _sendMessageUsecase;
  final ChatRepository _chatRepository;
  final String _chatContext;
  final _uuid = const Uuid();

  ChatViewModel({
    required ConnectChatUsecase connectChatUsecase,
    required DisconnectChatUsecase disconnectChatUsecase,
    required SendMessageUsecase sendMessageUsecase,
    required ChatRepository chatRepository,
    required String chatContext,
  })  : _connectChatUsecase = connectChatUsecase,
        _disconnectChatUsecase = disconnectChatUsecase,
        _sendMessageUsecase = sendMessageUsecase,
        _chatRepository = chatRepository,
        _chatContext = chatContext;

  StreamSubscription<ChatMessageEntity>? _messageSubscription;
  String? _currentUserId;
  DateTime? _currentDate;

  List<ChatMessageEntity> _messages = [];
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isSending = false;
  String? _error;

  List<ChatMessageEntity> get messages => _messages;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get isSending => _isSending;
  String? get error => _error;

  Future<void> connect(String userId, String userName, {dynamic workoutPlan}) async {
    _isConnecting = true;
    _error = null;
    notifyListeners();
    try {
      await ChatHistoryStorage.init();
      _currentUserId = userId;
      _currentDate = DateTime.now();

      final savedMessages = await ChatHistoryStorage.loadChatHistory(userId, _currentDate!, context: _chatContext);
      if (savedMessages.isNotEmpty) {
        _messages = savedMessages
            .map((m) => ChatMessageEntity(
                  id: m.id,
                  message: m.message,
                  userId: m.userId,
                  timestamp: m.timestamp,
                  isFromUser: m.isFromUser,
                ))
            .toList();
      }

      await _connectChatUsecase(userId, userName, workoutPlan: workoutPlan);
      _isConnected = true;

      _messageSubscription?.cancel();
      _messageSubscription = _chatRepository.messageStream.listen(
        _onMessageReceived,
        onError: (e) {
          _error = 'Connection error: $e';
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Failed to connect: $e';
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    try {
      await _messageSubscription?.cancel();
      await _disconnectChatUsecase();
      _isConnected = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to disconnect: $e';
      notifyListeners();
    }
  }

  Future<void> sendMessage(String message, String userId, {String? imagePath}) async {
    final userMessage = ChatMessageEntity(
      id: _uuid.v4(),
      message: message,
      userId: userId,
      timestamp: DateTime.now(),
      isFromUser: true,
      imagePath: imagePath,
    );
    _messages = [..._messages, userMessage];
    _isSending = true;
    notifyListeners();

    try {
      await _sendMessageUsecase(message: message, userId: userId);
      _saveChatHistory(_messages);
    } catch (e) {
      _messages = _messages.where((m) => m.id != userMessage.id).toList();
      _error = 'Failed to send message: $e';
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void _onMessageReceived(ChatMessageEntity message) {
    if (message.isFromUser) return;
    final exists = _messages.any((m) =>
        m.id == message.id ||
        (m.message == message.message &&
            m.timestamp.difference(message.timestamp).inSeconds.abs() < 2));
    if (!exists) {
      _messages = [..._messages, message];
      _saveChatHistory(_messages);
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }

  void _saveChatHistory(List<ChatMessageEntity> msgs) {
    if (_currentUserId == null || _currentDate == null) return;
    final models = msgs
        .map((e) => ChatMessageModel(
              id: e.id,
              message: e.message,
              userId: e.userId,
              timestamp: e.timestamp,
              isFromUser: e.isFromUser,
            ))
        .toList();
    ChatHistoryStorage.saveChatHistory(_currentUserId!, _currentDate!, models, context: _chatContext);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _disconnectChatUsecase();
    super.dispose();
  }
}
