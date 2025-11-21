import 'package:equatable/equatable.dart';

/// Entity representing a chat response from the backend
class ChatResponseEntity extends Equatable {
  final String message;
  final bool planUpdated;
  final Map<String, dynamic>? updatedPlanData;

  const ChatResponseEntity({
    required this.message,
    this.planUpdated = false,
    this.updatedPlanData,
  });

  @override
  List<Object?> get props => [message, planUpdated, updatedPlanData];
}

