part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  final List<ChatMessageEntity>? messages;

  const ChatState({this.messages});

  @override
  List<Object?> get props => [messages];
}

class ChatInitial extends ChatState {
  const ChatInitial() : super(messages: const []);
}

class ChatConnecting extends ChatState {
  const ChatConnecting({super.messages});
}

class ChatConnected extends ChatState {
  const ChatConnected({super.messages});
}

class ChatDisconnected extends ChatState {
  const ChatDisconnected({super.messages});
}

class ChatMessageSending extends ChatState {
  const ChatMessageSending({required super.messages});
}

class ChatMessageSent extends ChatState {
  final bool planUpdated;
  final Map<String, dynamic>? updatedPlanData;

  const ChatMessageSent({
    required super.messages,
    this.planUpdated = false,
    this.updatedPlanData,
  });

  @override
  List<Object?> get props => [messages, planUpdated, updatedPlanData];
}

class ChatMessageReceived extends ChatState {
  const ChatMessageReceived({required super.messages});
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message, {super.messages});

  @override
  List<Object?> get props => [message, messages];
}

