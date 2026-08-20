
import 'package:fitness/domain/models/user.dart';

abstract class AuthRepository {
  Future<UserEntity?> signInWithGoogle();
  Future<UserEntity?> signInWithGmail(String email);
  Future<UserEntity?> signUpWithEmail(String email, String password);
  Future<UserEntity?> signInWithEmail(String email, String password);
  Future<void> signOut();
  UserEntity? getCurrentUser();
  Future<void> deleteAccount();
}
