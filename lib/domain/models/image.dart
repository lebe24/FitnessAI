import 'package:equatable/equatable.dart';

class ImageEntities extends Equatable {
  final int id;
  final int userId;
  final dynamic image;
  final dynamic body;

  const ImageEntities({
    required this.id,
    required this.userId,
    this.image,
    required this.body,
  });

  @override
  List<Object> get props => [id, userId, image, body];
}
