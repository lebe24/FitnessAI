part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ConnectChat extends ChatEvent {
  final String userId;
  final String userName;
  final DateTime date;
  final Map<String, dynamic>? workoutPlan;

  const ConnectChat({
    required this.userId,
    required this.userName,
    required this.date,
    this.workoutPlan,
  });

  @override
  List<Object?> get props => [userId, userName, date, workoutPlan];
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

