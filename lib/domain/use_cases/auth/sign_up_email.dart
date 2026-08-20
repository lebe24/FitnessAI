import 'package:fitness/domain/models/user.dart';
import 'package:fitness/domain/repositories/auth_repository.dart';

class SignUpWithEmail {
  final AuthRepository repo;
  SignUpWithEmail(this.repo);

  Future<UserEntity?> call(String email, String password) =>
      repo.signUpWithEmail(email, password);
}
