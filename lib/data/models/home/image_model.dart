import 'package:fitness/domain/models/image.dart';

class AnalysisModel extends ImageEntities {
  const AnalysisModel({
    required super.id,
    required super.userId,
    required super.image,
    required super.body,
  });

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    return AnalysisModel(
      id: json['id'],
      userId: json['userId'],
      image: json['title'],
      body: json['body'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': image,
      'body': body,
    };
  }
}