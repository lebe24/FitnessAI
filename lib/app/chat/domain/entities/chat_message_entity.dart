import 'package:equatable/equatable.dart';

/// Entity representing a chat message
class ChatMessageEntity extends Equatable {
  final String id;
  final String message;
  final String userId;
  final DateTime timestamp;
  final bool isFromUser;

  const ChatMessageEntity({
    required this.id,
    required this.message,
    required this.userId,
    required this.timestamp,
    required this.isFromUser,
  });

  @override
  List<Object> get props => [id, message, userId, timestamp, isFromUser];
}

