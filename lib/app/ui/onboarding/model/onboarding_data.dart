class OnboardingData {
  final int? workoutDays;
  final String? gender;
  final String? goal;
  final String? height;
  final String? weight;
  final String? dob;

  const OnboardingData({this.height, this.weight, this.workoutDays, this.gender, this.goal, this.dob});

  OnboardingData copyWith({
    int? workoutDays,
    String? gender,
    String? goal,
    String? dob,
    String? height,
    String? weight,
  }) {
    return OnboardingData(
      workoutDays: workoutDays ?? this.workoutDays,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      dob: dob ?? this.dob,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }
}
