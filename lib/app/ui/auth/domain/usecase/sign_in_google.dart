import 'package:fitness/app/ui/auth/domain/entities/user_entity.dart';
import 'package:fitness/app/ui/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository repo;
  SignInWithGoogle(this.repo);

  Future<UserEntity?> call() {
    return repo.signInWithGoogle();
  }
}
