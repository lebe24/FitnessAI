import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';
import 'package:fitness/app/ui/home/domain/usecase/get_base_info_usecase.dart';
import 'package:fitness/app/ui/home/domain/usecase/upload_image_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

part 'upload_event.dart';
part 'upload_state.dart';

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  final UploadImageUseCase uploadImageUseCase;
  final GetBaseInfoUseCase getBaseInfoUseCase;
  final ImagePicker _picker = ImagePicker();

  UploadBloc({
    required this.uploadImageUseCase,
    required this.getBaseInfoUseCase,
  }) : super(UploadInitial()) {
    on<PickImageFromCamera>(_onPickFromCamera);
    on<PickImageFromGallery>(_onPickFromGallery);
    on<UploadImageToServer>(_onUploadImageToServer);
    on<TestBackendConnection>(_onTestBackendConnection);
  }

  Future<void> _onPickFromCamera(
      PickImageFromCamera event, Emitter<UploadState> emit) async {
    try {
      emit(const UploadLoading());
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        emit(UploadImageSelected(File(pickedFile.path)));
      } else {
        emit(const UploadFailure("No image captured."));
      }
    } catch (e) {
      emit(UploadFailure("Error: $e"));
    }
  }

  Future<void> _onPickFromGallery(
      PickImageFromGallery event, Emitter<UploadState> emit) async {
    try {
      emit(const UploadLoading());
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        emit(UploadImageSelected(File(pickedFile.path)));
      } else {
        emit(const UploadFailure("No image selected."));
      }
    } catch (e) {
      emit(UploadFailure("Error: $e"));
    }
  }

  Future<void> _onUploadImageToServer(
      UploadImageToServer event, Emitter<UploadState> emit) async {
    try {
      // Preserve the image while loading
      emit(UploadLoading(image: event.image));
      final result = await uploadImageUseCase.uploadImage(
        event.image,
        extraInfo: event.extraInfo,
        goal: event.goal,
        duration: event.duration,
        trainingSplit: event.trainingSplit,
      );
    
      // Format the workout plan result as a readable message
      // final message = _formatWorkoutPlanMessage(result);
      emit(UploadSeverSuccess( workoutPlan: result,));
    } catch (e) {
      // On error, preserve the image so user can retry
      emit(UploadFailure("Error uploading image: $e", image: event.image));
    }
  }

  String _formatWorkoutPlanMessage(WorkoutPlanEntity plan) {
    final buffer = StringBuffer();
    final data = plan.plan;
    
    buffer.writeln('📊 Analysis Summary:');
    buffer.writeln(data.analysisSummary);
    buffer.writeln('\n⭐ Physique Rating: ${data.physiqueRating}/100');
    buffer.writeln('\n🎯 Goal: ${data.goal}');
    buffer.writeln('💪 Focus: ${data.focus}');
    buffer.writeln('📅 Training Split: ${data.trainingSplit}');
    
    buffer.writeln('\n🏋️ Equipment Needed:');
    for (var equipment in data.equipment) {
      buffer.writeln('  • $equipment');
    }
    
    buffer.writeln('\n📋 Weekly Workout Plan:');
    for (var day in data.weeklySplit.days) {
      buffer.writeln('\n${day.day} - ${day.focus}');
      for (var exercise in day.exercises) {
        buffer.writeln('  • ${exercise.name}: ${exercise.sets} sets x ${exercise.reps}');
        if (exercise.notes != null) {
          buffer.writeln('    Note: ${exercise.notes}');
        }
      }
      if (day.tip != null) {
        buffer.writeln('  💡 Tip: ${day.tip}');
      }
    }
    
    buffer.writeln('\n📖 Training Guidelines:');
    buffer.writeln('  • Rest between sets: ${data.trainingGuidelines.restBetweenSets}');
    buffer.writeln('  • Progressive overload: ${data.trainingGuidelines.progressiveOverload}');
    buffer.writeln('  • Duration: ${data.trainingGuidelines.durationWeeks}');
    
    buffer.writeln('\n🥗 Nutrition Guidelines:');
    buffer.writeln('  • Protein: ${data.nutritionGuidelines.proteinPerKg}');
    buffer.writeln('  • Calorie surplus: ${data.nutritionGuidelines.calorieSurplus}');
    buffer.writeln('  • Hydration: ${data.nutritionGuidelines.hydration}');
    buffer.writeln('  • Sleep: ${data.nutritionGuidelines.sleep}');
    if (data.nutritionGuidelines.additionalNotes != null) {
      buffer.writeln('  • Additional notes: ${data.nutritionGuidelines.additionalNotes}');
    }
    
    if (data.extraTips.isNotEmpty) {
      buffer.writeln('\n💡 Extra Tips:');
      for (var tip in data.extraTips) {
        buffer.writeln('  • $tip');
      }
    }
    
    return buffer.toString();
  }

  Future<void> _onTestBackendConnection(
      TestBackendConnection event, Emitter<UploadState> emit) async {
    try {
      emit(const UploadLoading());
      final baseInfo = await getBaseInfoUseCase.call();
      emit(BaseInfoLoaded(baseInfo));
    } catch (e) {
      emit(UploadFailure("Error connecting to backend: $e"));
    }
  }
}
