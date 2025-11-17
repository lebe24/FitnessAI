
import 'package:fitness/app/ui/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> signInWithGoogle();
  Future<void> signOut();
  UserEntity? getCurrentUser();
}
