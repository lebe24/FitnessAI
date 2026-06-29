
import 'package:fitness/domain/models/user.dart';

abstract class AuthRepository {
  Future<UserEntity?> signInWithGoogle();
  Future<UserEntity?> signInWithGmail(String email);
  Future<void> signOut();
  UserEntity? getCurrentUser();
  Future<void> deleteAccount();
}
