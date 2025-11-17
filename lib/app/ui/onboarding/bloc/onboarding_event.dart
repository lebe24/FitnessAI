abstract class OnboardingEvent {}

class SelectWorkoutDays extends OnboardingEvent {
  final int days;
  SelectWorkoutDays(this.days);
}

class SelectGender extends OnboardingEvent {
  final String gender;
  SelectGender(this.gender);
}

class SelectGoal extends OnboardingEvent {
  final String goal;
  SelectGoal(this.goal);
}

class SelectHeight extends OnboardingEvent {
  final String height;
  SelectHeight(this.height);
}

class ToggleUnitSystem extends OnboardingEvent {
  final bool isMetric;
  ToggleUnitSystem(this.isMetric);
}

class SelectHeightFt extends OnboardingEvent {
  final int feet;
  final int inches;
  SelectHeightFt(this.feet, this.inches);
}

class SelectHeightMeters extends OnboardingEvent {
  final double meters;
  SelectHeightMeters(this.meters);
}

class SelectWeight extends OnboardingEvent {
  final String weight;
  SelectWeight(this.weight);
}

class SelectWeightWt extends OnboardingEvent {
  final int? kg;
  final int? lbs;
  SelectWeightWt({this.kg, this.lbs});
}

class SelectDob extends OnboardingEvent {
  final String dob;
  SelectDob(this.dob);
}

class NextStep extends OnboardingEvent {}

class PreviousStep extends OnboardingEvent {}

