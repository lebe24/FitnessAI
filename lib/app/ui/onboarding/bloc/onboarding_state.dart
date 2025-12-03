
import 'package:fitness/app/ui/onboarding/model/onboarding_data.dart';

enum OnboardingStep {
  gender,
  workoutDays,
  goal,
  experience,
  heightAndWeight,
  dob,
  signup,
  summary
}

class OnboardingState {
  final OnboardingData data;
  final OnboardingStep step;
  
  // Height and Weight specific state
  final bool isMetric;
  final int selectedFeet;
  final int selectedInches;
  final double selectedMeters; // Height in meters (e.g., 1.70 for 1.70m)
  final int selectedKg;
  final int selectedLbs;

  const OnboardingState({
    required this.data,
    required this.step,
    this.isMetric = false,
    this.selectedFeet = 5,
    this.selectedInches = 6,
    this.selectedMeters = 1.70,
    this.selectedKg = 60,
    this.selectedLbs = 119,
  });

  OnboardingState copyWith({
    OnboardingData? data,
    OnboardingStep? step,
    bool? isMetric,
    int? selectedFeet,
    int? selectedInches,
    double? selectedMeters,
    int? selectedKg,
    int? selectedLbs,
  }) {
    return OnboardingState(
      data: data ?? this.data,
      step: step ?? this.step,
      isMetric: isMetric ?? this.isMetric,
      selectedFeet: selectedFeet ?? this.selectedFeet,
      selectedInches: selectedInches ?? this.selectedInches,
      selectedMeters: selectedMeters ?? this.selectedMeters,
      selectedKg: selectedKg ?? this.selectedKg,
      selectedLbs: selectedLbs ?? this.selectedLbs,
    );
  }
}

