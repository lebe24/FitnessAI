import 'package:fitness/domain/models/user.dart';
import 'package:fitness/domain/models/profile.dart';

class ProfileModel extends ProfileEntity {
  ProfileModel({
    super.user,
    super.name,
    super.email,
    super.avatarUrl,
    super.age,
    super.dob,
    super.gender,
    super.height,
    super.weight,
    super.goal,
    super.experience,
    super.workoutDays,
  });

  /// Calculate age from date of birth (YYYY-MM-DD format)
  static int? calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    
    try {
      final parts = dob.split('-');
      if (parts.length != 3) return null;
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      final birthDate = DateTime(year, month, day);
      final today = DateTime.now();
      
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      
      return age;
    } catch (e) {
      return null;
    }
  }

  /// Create ProfileModel from UserEntity and onboarding data
  factory ProfileModel.fromUserAndOnboarding({
    required UserEntity? user,
    String? dob,
    String? gender,
    String? height,
    String? weight,
    String? goal,
    String? experience,
    int? workoutDays,
  }) {
    return ProfileModel(
      user: user,
      name: user?.name,
      email: user?.email,
      avatarUrl: user?.avatarUrl,
      age: calculateAge(dob),
      dob: dob,
      gender: gender,
      height: height,
      weight: weight,
      goal: goal,
      experience: experience,
      workoutDays: workoutDays,
    );
  }
}

