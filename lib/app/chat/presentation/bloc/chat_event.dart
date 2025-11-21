part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ConnectChat extends ChatEvent {
  final String userId;
  final Map<String, dynamic>? workoutPlan;

  const ConnectChat(this.userId, {this.workoutPlan});

  @override
  List<Object?> get props => [userId, workoutPlan];
}

class DisconnectChat extends ChatEvent {
  const DisconnectChat();
}

class SendMessage extends ChatEvent {
  final String message;
  final String userId;

  const SendMessage({
    required this.message,
    required this.userId,
  });

  @override
  List<Object?> get props => [message, userId];
}

class MessageReceived extends ChatEvent {
  final ChatMessageEntity message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class ClearMessages extends ChatEvent {
  const ClearMessages();
}

