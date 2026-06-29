import 'package:fitness/domain/models/chat_response.dart';
import 'package:fitness/domain/repositories/chat_repository.dart';

/// Use case for sending a message to the chat server
class SendMessageUsecase {
  final ChatRepository repository;

  SendMessageUsecase(this.repository);

  Future<ChatResponseEntity> call({
    required String message,
    required String userId,
  }) async {
    return await repository.sendMessage(
      message: message,
      userId: userId,
    );
  }
}

