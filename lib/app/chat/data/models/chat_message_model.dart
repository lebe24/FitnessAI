import 'package:fitness/app/chat/domain/entities/chat_message_entity.dart';

/// Model representing a chat message
class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.message,
    required super.userId,
    required super.timestamp,
    required super.isFromUser,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    // Handle backend format: { type: 'message', role: 'user'|'assistant', content: '...' }
    // Or legacy format: { message: '...', isFromUser: bool }
    final String messageContent;
    final bool isFromUser;
    
    if (json.containsKey('type') && json['type'] == 'message') {
      // New format from backend
      messageContent = json['content'] as String? ?? json['message'] as String? ?? '';
      final role = json['role'] as String?;
      isFromUser = role == 'user';
    } else {
      // Legacy format
      messageContent = json['message'] as String? ?? json['content'] as String? ?? '';
      isFromUser = json['isFromUser'] as bool? ?? false;
    }
    
    return ChatMessageModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      message: messageContent,
      userId: json['userId'] as String? ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isFromUser: isFromUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'isFromUser': isFromUser,
    };
  }

  factory ChatMessageModel.fromEntity(ChatMessageEntity entity) {
    return ChatMessageModel(
      id: entity.id,
      message: entity.message,
      userId: entity.userId,
      timestamp: entity.timestamp,
      isFromUser: entity.isFromUser,
    );
  }
}

