import 'package:fitness/domain/models/profile.dart';
import 'package:fitness/domain/use_cases/profile/get_profile_usecase.dart';
import 'package:flutter/foundation.dart';

class ProfileViewModel extends ChangeNotifier {
  final GetProfileUseCase _getProfileUseCase;

  ProfileViewModel({required GetProfileUseCase getProfileUseCase})
      : _getProfileUseCase = getProfileUseCase;

  ProfileEntity? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileEntity? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _getProfileUseCase();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadProfile();
}
