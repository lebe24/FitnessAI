import 'package:fitness/app/chat/data/datasources/chat_remote_datasource.dart';
import 'package:fitness/app/chat/data/models/chat_message_model.dart';
import 'package:fitness/app/chat/data/models/chat_response_model.dart';
import 'package:fitness/app/chat/domain/entities/chat_message_entity.dart';
import 'package:fitness/app/chat/domain/entities/chat_response_entity.dart';
import 'package:fitness/app/chat/domain/repositories/chat_repository.dart';

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

