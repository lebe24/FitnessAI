import 'package:fitness/domain/models/user.dart';
import 'package:fitness/domain/models/profile.dart';
import 'package:fitness/domain/repositories/auth_repository.dart';
import 'package:fitness/data/services/auth/auth_remote_service.dart';
import 'package:fitness/data/services/profile/profile_remote_service.dart';
import 'package:fitness/data/services/profile/profile_local_service.dart';
import 'package:fitness/data/models/auth/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final ProfileRemoteDataSource profileRemote;
  final ProfileLocalDataSource profileLocal;

  AuthRepositoryImpl(this.remote, this.profileRemote, this.profileLocal);

  Future<UserEntity> _buildAndSyncUser(dynamic user) async {
    final entity = UserModel(
      id: user.id,
      email: user.email,
      name: user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String? ??
                 user.userMetadata?['picture'] as String?,
    );
    // Merge onboarding fields (gender, dob, height, weight, goal, experience,
    // workoutDays) so the user_profiles row is fully populated on every sign-in.
    // Swallowed on failure — backend being unreachable must not block sign-in.
    try {
      final onboarding = await profileLocal.getOnboardingData();
      await profileRemote.upsertProfile(ProfileEntity(
        user:        entity,
        name:        entity.name,
        email:       entity.email,
        avatarUrl:   entity.avatarUrl,
        gender:      onboarding?.gender,
        dob:         onboarding?.dob,
        height:      onboarding?.height,
        weight:      onboarding?.weight,
        goal:        onboarding?.goal,
        experience:  onboarding?.experience,
        workoutDays: onboarding?.workoutDays,
      ));
    } catch (_) {}
    return entity;
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    final user = await remote.signInWithGoogle();
    return _buildAndSyncUser(user);
  }

  @override
  Future<UserEntity?> signInWithGmail(String email) async {
    final user = await remote.signInWithGmail(email);
    return _buildAndSyncUser(user);
  }

  @override
  Future<void> signOut() => remote.signOut();

  @override
  UserEntity? getCurrentUser() => remote.getCurrentUser();

  @override
  Future<void> deleteAccount() => remote.deleteAccount();
}
