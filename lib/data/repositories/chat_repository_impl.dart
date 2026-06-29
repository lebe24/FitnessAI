import 'package:fitness/data/services/chat/chat_remote_service.dart';
import 'package:fitness/data/models/chat/chat_message_model.dart';
import 'package:fitness/data/models/chat/chat_response_model.dart';
import 'package:fitness/domain/models/chat_message.dart';
import 'package:fitness/domain/models/chat_response.dart';
import 'package:fitness/domain/repositories/chat_repository.dart';

/// Implementation of ChatRepository
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> connect(String userId, String userName, {Map<String, dynamic>? workoutPlan}) async {
    return await remoteDataSource.connect(userId, userName, workoutPlan: workoutPlan);
  }

  @override
  Future<void> disconnect() async {
    return await remoteDataSource.disconnect();
  }

  @override
  Future<ChatResponseEntity> sendMessage({
    required String message,
    required String userId,
  }) async {
    final response = await remoteDataSource.sendMessage(
      message: message,
      userId: userId,
    );
    return response;
  }

  @override
  Stream<ChatMessageEntity> get messageStream {
    return remoteDataSource.messageStream.map(
      (model) => model as ChatMessageEntity,
    );
  }

  @override
  bool get isConnected => remoteDataSource.isConnected;
}

