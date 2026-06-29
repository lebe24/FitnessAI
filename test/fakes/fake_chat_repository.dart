import 'dart:async';
import 'package:fitness/domain/models/chat_message.dart';
import 'package:fitness/domain/models/chat_response.dart';
import 'package:fitness/domain/repositories/chat_repository.dart';
import '../fixtures/fixtures.dart';

class FakeChatRepository implements ChatRepository {
  final _controller = StreamController<ChatMessageEntity>.broadcast();

  bool connected = false;
  Exception? connectError;
  Exception? sendError;
  ChatResponseEntity sendResult = Fixtures.chatResponse();

  bool connectCalled = false;
  bool disconnectCalled = false;
  String? lastConnectedUserId;
  String? lastSentMessage;

  @override
  bool get isConnected => connected;

  @override
  Stream<ChatMessageEntity> get messageStream => _controller.stream;

  @override
  Future<void> connect(
    String userId,
    String userName, {
    Map<String, dynamic>? workoutPlan,
  }) async {
    if (connectError != null) throw connectError!;
    connectCalled = true;
    lastConnectedUserId = userId;
    connected = true;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
    connected = false;
  }

  @override
  Future<ChatResponseEntity> sendMessage({
    required String message,
    required String userId,
  }) async {
    if (sendError != null) throw sendError!;
    lastSentMessage = message;
    return sendResult;
  }

  void dispose() => _controller.close();
}
