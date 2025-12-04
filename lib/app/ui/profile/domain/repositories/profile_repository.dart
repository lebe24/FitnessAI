import 'package:fitness/app/ui/profile/domain/entities/profile_entity.dart';

abstract class ProfileRepository {
  /// Get the complete user profile combining auth and onboarding data
  Future<ProfileEntity> getProfile();
}

