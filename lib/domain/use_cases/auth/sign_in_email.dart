import 'package:fitness/domain/models/user.dart';
import 'package:fitness/domain/repositories/auth_repository.dart';

class SignInWithEmail {
  final AuthRepository repo;
  SignInWithEmail(this.repo);

  Future<UserEntity?> call(String email, String password) =>
      repo.signInWithEmail(email, password);
}
