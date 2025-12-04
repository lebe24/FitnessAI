import 'package:fitness/app/ui/auth/domain/usecase/get_current_user.dart';
import 'package:fitness/app/ui/profile/data/datasources/profile_local_datasource.dart';
import 'package:fitness/app/ui/profile/data/models/profile_model.dart';
import 'package:fitness/app/ui/profile/domain/entities/profile_entity.dart';
import 'package:fitness/app/ui/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSource localDataSource;
  final GetCurrentUser getCurrentUser;

  ProfileRepositoryImpl({
    required this.localDataSource,
    required this.getCurrentUser,
  });

  @override
  Future<ProfileEntity> getProfile() async {
    // Get user from auth
    final user = getCurrentUser();
    
    // Get onboarding data from local storage
    final onboardingData = await localDataSource.getOnboardingData();
    
    // Combine both into profile
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
}

