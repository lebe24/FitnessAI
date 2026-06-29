import 'package:fitness/data/models/onboarding/onboarding_data.dart';
import 'package:fitness/ui/features/onboarding/views/onboarding_storage.dart';
import 'package:flutter/foundation.dart';

enum OnboardingStep {
  gender,
  workoutDays,
  goal,
  experience,
  heightAndWeight,
  dob,
  signup,
  summary,
  decide,
  motivationQuote,
}

class OnboardingViewModel extends ChangeNotifier {
  OnboardingData _data;
  OnboardingStep _step;
  bool _isMetric;
  int _selectedFeet;
  int _selectedInches;
  double _selectedMeters;
  int _selectedKg;
  int _selectedLbs;

  OnboardingViewModel({OnboardingData? initialData})
      : _data = initialData ?? const OnboardingData(),
        _step = OnboardingStep.gender,
        _isMetric = false,
        _selectedFeet = 5,
        _selectedInches = 6,
        _selectedMeters = 1.70,
        _selectedKg = 60,
        _selectedLbs = 119;

  OnboardingData get data => _data;
  OnboardingStep get step => _step;
  bool get isMetric => _isMetric;
  int get selectedFeet => _selectedFeet;
  int get selectedInches => _selectedInches;
  double get selectedMeters => _selectedMeters;
  int get selectedKg => _selectedKg;
  int get selectedLbs => _selectedLbs;

  // ── Selection commands (each autosaves) ──────────────────────────────────

  void selectGender(String gender) {
    _data = _data.copyWith(gender: gender);
    _autosave();
    notifyListeners();
  }

  void selectGoal(String goal) {
    _data = _data.copyWith(goal: goal);
    _autosave();
    notifyListeners();
  }

  void selectWorkoutDays(int days) {
    _data = _data.copyWith(workoutDays: days);
    _autosave();
    notifyListeners();
  }

  void selectHeight(String height) {
    _data = _data.copyWith(height: height);
    _autosave();
    notifyListeners();
  }

  void selectWeight(String weight) {
    _data = _data.copyWith(weight: weight);
    _autosave();
    notifyListeners();
  }

  void toggleUnitSystem(bool isMetric) {
    _isMetric = isMetric;
    notifyListeners();
  }

  void selectHeightFt(int feet, int inches) {
    _selectedFeet = feet;
    _selectedInches = inches;
    notifyListeners();
  }

  void selectHeightMeters(double meters) {
    _selectedMeters = meters;
    notifyListeners();
  }

  void selectWeightValues({int? kg, int? lbs}) {
    if (kg != null) _selectedKg = kg;
    if (lbs != null) _selectedLbs = lbs;
    notifyListeners();
  }

  void selectDob(String dob) {
    _data = _data.copyWith(dob: dob);
    _autosave();
    notifyListeners();
  }

  void selectExperience(String experience) {
    _data = _data.copyWith(experience: experience);
    _autosave();
    notifyListeners();
  }

  void nextStep() {
    _step = _nextStep(_step);
    notifyListeners();
  }

  void previousStep() {
    _step = _prevStep(_step);
    notifyListeners();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  /// Fire-and-forget autosave after each data mutation.
  void _autosave() => OnboardingStorage.saveOnboardingData(_data);

  OnboardingStep _nextStep(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.gender:           return OnboardingStep.workoutDays;
      case OnboardingStep.workoutDays:      return OnboardingStep.goal;
      case OnboardingStep.goal:             return OnboardingStep.experience;
      case OnboardingStep.experience:       return OnboardingStep.heightAndWeight;
      case OnboardingStep.heightAndWeight:  return OnboardingStep.dob;
      case OnboardingStep.dob:              return OnboardingStep.signup;
      case OnboardingStep.signup:           return OnboardingStep.summary;
      case OnboardingStep.summary:          return OnboardingStep.decide;
      case OnboardingStep.decide:           return OnboardingStep.motivationQuote;
      case OnboardingStep.motivationQuote:  return OnboardingStep.motivationQuote;
    }
  }

  OnboardingStep _prevStep(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.motivationQuote:  return OnboardingStep.decide;
      case OnboardingStep.decide:           return OnboardingStep.summary;
      case OnboardingStep.summary:          return OnboardingStep.signup;
      case OnboardingStep.signup:           return OnboardingStep.dob;
      case OnboardingStep.dob:              return OnboardingStep.heightAndWeight;
      case OnboardingStep.heightAndWeight:  return OnboardingStep.experience;
      case OnboardingStep.experience:       return OnboardingStep.goal;
      case OnboardingStep.goal:             return OnboardingStep.workoutDays;
      case OnboardingStep.workoutDays:      return OnboardingStep.gender;
      case OnboardingStep.gender:           return OnboardingStep.gender;
    }
  }
}
