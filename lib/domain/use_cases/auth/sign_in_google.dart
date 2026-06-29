import 'package:fitness/domain/models/user.dart';
import 'package:fitness/domain/repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository repo;
  SignInWithGoogle(this.repo);

  Future<UserEntity?> call() {
    return repo.signInWithGoogle();
  }
}
