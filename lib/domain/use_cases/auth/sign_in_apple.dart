import 'package:fitness/domain/models/user.dart';
import 'package:fitness/domain/repositories/auth_repository.dart';

class SignInWithApple {
  final AuthRepository repo;
  SignInWithApple(this.repo);

  Future<UserEntity?> call() {
    return repo.signInWithApple();
  }
}
