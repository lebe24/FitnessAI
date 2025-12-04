import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../model/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  AuthRepositoryImpl(this.remote);

  @override
  Future<UserEntity?> signInWithGoogle() async {
    final user = await remote.signInWithGoogle();
    
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.userMetadata?['full_name'] as String? ?? 
            user.userMetadata?['name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String? ??
                 user.userMetadata?['picture'] as String?,
    );
  }

  @override
  Future<void> signOut() => remote.signOut();

  @override
  UserEntity? getCurrentUser() => remote.getCurrentUser();

  @override
  Future<void> deleteAccount() => remote.deleteAccount();
}
