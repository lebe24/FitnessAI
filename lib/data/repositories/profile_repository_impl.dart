import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/data/services/profile/profile_local_service.dart';
import 'package:fitness/data/services/profile/profile_remote_service.dart';
import 'package:fitness/data/models/profile/profile_model.dart';
import 'package:fitness/domain/models/profile.dart';
import 'package:fitness/domain/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSource localDataSource;
  final ProfileRemoteDataSource remoteDataSource;
  final GetCurrentUser getCurrentUser;

  ProfileRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.getCurrentUser,
  });

  @override
  Future<ProfileEntity> getProfile() async {
    final user = getCurrentUser();
    final onboardingData = await localDataSource.getOnboardingData();
    return ProfileModel.fromUserAndOnboarding(
      user: user,
      dob: onboardingData?.dob,
      gender: onboardingData?.gender,
      height: onboardingData?.height,
      weight: onboardingData?.weight,
      goal: onboardingData?.goal,
      experience: onboardingData?.experience,
      workoutDays: onboardingData?.workoutDays,
    );
  }

  @override
  Future<void> syncToRemote() async {
    try {
      final profile = await getProfile();
      await remoteDataSource.upsertProfile(profile);
    } catch (e) {
      // Log but don't throw — auth should succeed even if profile sync fails
      debugPrint('ProfileRepository.syncToRemote failed: $e');
    }
  }
}

