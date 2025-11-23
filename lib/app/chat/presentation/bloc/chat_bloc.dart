import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:fitness/app/chat/data/helpers/chat_history_storage.dart';
import 'package:fitness/app/chat/data/models/chat_message_model.dart';
import 'package:fitness/app/chat/domain/entities/chat_message_entity.dart';
import 'package:fitness/app/chat/domain/repositories/chat_repository.dart';
import 'package:fitness/app/chat/domain/usecases/connect_chat_usecase.dart';
import 'package:fitness/app/chat/domain/usecases/disconnect_chat_usecase.dart';
import 'package:fitness/app/chat/domain/usecases/send_message_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ConnectChatUsecase connectChatUsecase;
  final DisconnectChatUsecase disconnectChatUsecase;
  final SendMessageUsecase sendMessageUsecase;
  final ChatRepository chatRepository;
  final _uuid = const Uuid();

  StreamSubscription<ChatMessageEntity>? _messageSubscription;
  String? _currentUserId;
  DateTime? _currentDate;

  ChatBloc({
    required this.connectChatUsecase,
    required this.disconnectChatUsecase,
    required this.sendMessageUsecase,
    required this.chatRepository,
  }) : super(ChatInitial()) {
    on<ConnectChat>(_onConnectChat);
    on<DisconnectChat>(_onDisconnectChat);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<ClearMessages>(_onClearMessages);
  }

  Future<void> _onConnectChat(
    ConnectChat event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatConnecting());
    try {
      // Initialize chat history storage
      await ChatHistoryStorage.init();
      
      // Store current user and date for saving history
      _currentUserId = event.userId;
      _currentDate = event.date;
      
      // Load chat history for this date
      final savedMessages = await ChatHistoryStorage.loadChatHistory(
        event.userId,
        event.date,
      );
      
      // Convert saved messages to entities (ChatMessageModel extends ChatMessageEntity)
      final savedMessageEntities = savedMessages
          .map((model) => ChatMessageEntity(
                id: model.id,
                message: model.message,
                userId: model.userId,
                timestamp: model.timestamp,
                isFromUser: model.isFromUser,
              ))
          .toList();
      
      // If we have saved messages, emit them
      if (savedMessageEntities.isNotEmpty) {
        emit(ChatConnected(messages: savedMessageEntities));
      } else {
        emit(ChatConnected());
      }
      
      await connectChatUsecase(event.userId, event.userName, workoutPlan: event.workoutPlan);

      // Listen to incoming messages
      _messageSubscription?.cancel();
      _messageSubscription = chatRepository.messageStream.listen(
        (message) {
          add(MessageReceived(message));
        },
        onError: (error) {
          emit(ChatError('Connection error: $error'));
        },
      );
    } catch (e) {
      emit(ChatError('Failed to connect: $e'));
    }
  }

  Future<void> _onDisconnectChat(
    DisconnectChat event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _messageSubscription?.cancel();
      await disconnectChatUsecase();
      emit(ChatDisconnected());
    } catch (e) {
      emit(ChatError('Failed to disconnect: $e'));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    // Add user message to the list immediately (matching HTML implementation)
    final userMessage = ChatMessageEntity(
      id: _uuid.v4(),
      message: event.message,
      userId: event.userId,
      timestamp: DateTime.now(),
      isFromUser: true,
    );

    final currentMessages = state.messages ?? [];
    emit(ChatMessageSending(
      messages: [...currentMessages, userMessage],
    ));

    try {
      // Send message - response will come through messageStream
      await sendMessageUsecase(
        message: event.message,
        userId: event.userId,
      );

      // Message sent successfully, keep the user message in state
      // AI response will come through MessageReceived event
      final updatedMessages = [...currentMessages, userMessage];
      emit(ChatMessageSent(
        messages: updatedMessages,
        planUpdated: false,
        updatedPlanData: null,
      ));
      
      // Save chat history
      _saveChatHistory(updatedMessages);
    } catch (e) {
      // On error, remove the user message we just added
      emit(ChatError('Failed to send message: $e', messages: currentMessages));
    }
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final currentMessages = state.messages ?? [];
    
    // Only add assistant messages from stream (user messages are already added when sending)
    // This prevents duplicate user messages
    if (!event.message.isFromUser) {
      // Check if message already exists (prevent duplicates)
      final messageExists = currentMessages.any(
        (msg) => msg.id == event.message.id || 
                 (msg.message == event.message.message && 
                  msg.timestamp.difference(event.message.timestamp).inSeconds.abs() < 2),
      );
      
      if (!messageExists) {
        final updatedMessages = [...currentMessages, event.message];
        emit(ChatMessageReceived(
          messages: updatedMessages,
        ));
        
        // Save chat history
        _saveChatHistory(updatedMessages);
      }
    }
  }
  
  /// Save chat history to local storage
  void _saveChatHistory(List<ChatMessageEntity> messages) {
    if (_currentUserId != null && _currentDate != null) {
      final messageModels = messages.map((entity) {
        return ChatMessageModel(
          id: entity.id,
          message: entity.message,
          userId: entity.userId,
          timestamp: entity.timestamp,
          isFromUser: entity.isFromUser,
        );
      }).toList();
      
      ChatHistoryStorage.saveChatHistory(
        _currentUserId!,
        _currentDate!,
        messageModels,
      );
    }
  }

  void _onClearMessages(
    ClearMessages event,
    Emitter<ChatState> emit,
  ) {
    emit(ChatInitial());
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    disconnectChatUsecase();
    return super.close();
  }
}

