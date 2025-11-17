part of 'upload_bloc.dart';

abstract class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

class UploadInitial extends UploadState {}

class UploadLoading extends UploadState {
  final File? image;
  const UploadLoading({this.image});
  
  @override
  List<Object?> get props => [image];
}

class UploadSuccess extends UploadState {
  final String message;
  const UploadSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class UploadFailure extends UploadState {
  final String message;
  final File? image;
  const UploadFailure(this.message, {this.image});

  @override
  List<Object?> get props => [message, image];
}



class UploadImageSelected extends UploadState {
  final File image;
  const UploadImageSelected(this.image);

  @override
  List<Object?> get props => [image];
}

class UploadedImageFromCamera extends UploadState {
  final File image;
  const UploadedImageFromCamera(this.image);

  @override
  List<Object?> get props => [image];
}

class UploadSeverSuccess extends UploadState {
  final WorkoutPlanEntity? workoutPlan;
  const UploadSeverSuccess({this.workoutPlan});

  @override
  List<Object?> get props => [workoutPlan];
}

class BaseInfoLoaded extends UploadState {
  final String baseInfo;
  const BaseInfoLoaded(this.baseInfo);

  @override
  List<Object?> get props => [baseInfo];
}
