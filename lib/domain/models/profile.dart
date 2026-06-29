import 'package:fitness/domain/models/user.dart';

class ProfileEntity {
  final UserEntity? user;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final int? age;
  final String? dob;
  final String? gender;
  final String? height;
  final String? weight;
  final String? goal;
  final String? experience;
  final int? workoutDays;

  ProfileEntity({
    this.user,
    this.name,
    this.email,
    this.avatarUrl,
    this.age,
    this.dob,
    this.gender,
    this.height,
    this.weight,
    this.goal,
    this.experience,
    this.workoutDays,
  });

  /// Get the initial letter for avatar
  String get initial {
    if (name != null && name!.isNotEmpty) {
      return name!.substring(0, 1).toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email!.substring(0, 1).toUpperCase();
    }
    return '?';
  }

  /// Get formatted age string
  String get ageString {
    if (age != null) {
      return '$age years old';
    }
    return '';
  }
}

