import 'package:fitness/domain/models/chat_message.dart';

/// Model representing a chat message
class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.message,
    required super.userId,
    required super.timestamp,
    required super.isFromUser,
    super.uiComponent,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    // Handle backend format: { type: 'message', role: 'user'|'assistant', content: '...' }
    // Or legacy format: { message: '...', isFromUser: bool }
    final String messageContent;
    final bool isFromUser;

    if (json.containsKey('type') && json['type'] == 'message') {
      messageContent = json['content'] as String? ?? json['message'] as String? ?? '';
      final role = json['role'] as String?;
      isFromUser = role == 'user';
    } else {
      messageContent = json['message'] as String? ?? json['content'] as String? ?? '';
      isFromUser = json['isFromUser'] as bool? ?? false;
    }

    // Parse optional interactive UI component sent by the backend
    final uiComponent = json['ui'] as Map<String, dynamic>?;

    return ChatMessageModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      message: messageContent,
      userId: json['userId'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isFromUser: isFromUser,
      uiComponent: uiComponent,
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
      uiComponent: entity.uiComponent,
    );
  }
}
