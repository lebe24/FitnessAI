import 'package:fitness/app/chat/domain/repositories/chat_repository.dart';

/// Use case for connecting to the chat WebSocket
class ConnectChatUsecase {
  final ChatRepository repository;

  ConnectChatUsecase(this.repository);

  Future<void> call(String userId, {Map<String, dynamic>? workoutPlan}) async {
    return await repository.connect(userId, workoutPlan: workoutPlan);
  }
}

