import 'package:fitness/app/ui/auth/domain/entities/user_entity.dart';
import 'package:fitness/app/ui/auth/domain/repositories/auth_repository.dart';

class SignInWithGmail {
  final AuthRepository repo;
  SignInWithGmail(this.repo);

  Future<UserEntity?> call(String email) {
    return repo.signInWithGmail(email);
  }
}

