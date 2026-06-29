import 'package:fitness/domain/repositories/chat_repository.dart';

/// Use case for disconnecting from the chat WebSocket
class DisconnectChatUsecase {
  final ChatRepository repository;

  DisconnectChatUsecase(this.repository);

  Future<void> call() async {
    return await repository.disconnect();
  }
}

