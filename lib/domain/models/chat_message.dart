import 'package:equatable/equatable.dart';

/// Entity representing a chat message.
///
/// [uiComponent] carries an optional interactive widget descriptor from the
/// backend (e.g. a chip-selector for muscle groups).  It is not part of
/// Equatable [props] so message identity is still driven by [id].
class ChatMessageEntity extends Equatable {
  final String id;
  final String message;
  final String userId;
  final DateTime timestamp;
  final bool isFromUser;

  /// Interactive UI component, e.g.:
  /// ```json
  /// {
  ///   "type": "chip_select",
  ///   "id": "muscle_groups",
  ///   "title": "Which muscle groups?",
  ///   "multi": true,
  ///   "options": [{"id":"chest","label":"Chest","emoji":"💪"}, ...]
  /// }
  /// ```
  final Map<String, dynamic>? uiComponent;

  /// Local file path of an attached image (user messages only).
  final String? imagePath;

  const ChatMessageEntity({
    required this.id,
    required this.message,
    required this.userId,
    required this.timestamp,
    required this.isFromUser,
    this.uiComponent,
    this.imagePath,
  });

  @override
  List<Object> get props => [id, message, userId, timestamp, isFromUser];
}

