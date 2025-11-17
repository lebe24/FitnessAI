part of 'upload_bloc.dart';

abstract class UploadEvent extends Equatable {
  const UploadEvent();

  @override
  List<Object?> get props => [];
}

class PickImageFromCamera extends UploadEvent {}

class PickImageFromGallery extends UploadEvent {}

// class UploadImageToServer extends UploadEvent {}


class UploadImageToServer extends UploadEvent {
  final File image;
  final String? extraInfo;
  final String goal;
  final String duration;
  final String trainingSplit;
  
  const UploadImageToServer({
    required this.image,
    this.extraInfo,
    required this.goal,
    required this.duration,
    required this.trainingSplit,
  });
  
  @override
  List<Object?> get props => [image, extraInfo, goal, duration, trainingSplit];
}

class TestBackendConnection extends UploadEvent {}
