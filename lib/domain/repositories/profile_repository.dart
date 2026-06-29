import 'package:fitness/domain/models/profile.dart';

abstract class ProfileRepository {
  /// Get the complete user profile combining auth and onboarding data
  Future<ProfileEntity> getProfile();

  /// Upsert the profile to the backend `user_profiles` table.
  ///
  /// MUST be called after every sign-in so the FK constraint on all other
  /// tables (workout_sessions, exercise_logs, nutrition_logs, etc.) is satisfied.
  Future<void> syncToRemote();
}

