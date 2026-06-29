import 'dart:io';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/domain/use_cases/home/get_base_info_usecase.dart';
import 'package:fitness/domain/use_cases/home/upload_image_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class UploadViewModel extends ChangeNotifier {
  final UploadImageUseCase _uploadImageUseCase;
  final GetBaseInfoUseCase _getBaseInfoUseCase;
  final ImagePicker _picker = ImagePicker();

  UploadViewModel({
    required UploadImageUseCase uploadImageUseCase,
    required GetBaseInfoUseCase getBaseInfoUseCase,
  })  : _uploadImageUseCase = uploadImageUseCase,
        _getBaseInfoUseCase = getBaseInfoUseCase;

  File? _image;
  WorkoutPlanEntity? _workoutPlan;
  dynamic _baseInfo;
  bool _isLoading = false;
  String? _error;

  File? get image => _image;
  WorkoutPlanEntity? get workoutPlan => _workoutPlan;
  dynamic get baseInfo => _baseInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> pickFromCamera() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked != null) {
        _image = File(picked.path);
      } else {
        _error = 'No image captured.';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickFromGallery() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        _image = File(picked.path);
      } else {
        _error = 'No image selected.';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> upload({
    required File image,
    String? extraInfo,
    required String goal,
    required String duration,
    required String trainingSplit,
    required String gender,
    required String height,
    required String weight,
    required String experience,
  }) async {
    _isLoading = true;
    _error = null;
    _image = image;
    notifyListeners();
    try {
      _workoutPlan = await _uploadImageUseCase.uploadImage(
        image,
        extraInfo: extraInfo,
        goal: goal,
        duration: duration,
        trainingSplit: trainingSplit,
        gender: gender,
        height: height,
        weight: weight,
        experience: experience,
      );
    } catch (e) {
      _error = 'Error uploading image: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> testBackendConnection() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _baseInfo = await _getBaseInfoUseCase.call();
    } catch (e) {
      _error = 'Error connecting to backend: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
