import 'package:fitness/domain/models/chat_response.dart';

/// Model representing a chat response from the backend
class ChatResponseModel extends ChatResponseEntity {
  const ChatResponseModel({
    required super.message,
    super.planUpdated = false,
    super.updatedPlanData,
  });

  factory ChatResponseModel.fromJson(Map<String, dynamic> json) {
    return ChatResponseModel(
      message: json['message'] as String,
      planUpdated: json['planUpdated'] as bool? ?? false,
      updatedPlanData: json['updatedPlanData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'planUpdated': planUpdated,
      if (updatedPlanData != null) 'updatedPlanData': updatedPlanData,
    };
  }
}

