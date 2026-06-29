import 'package:fitness/domain/models/user.dart';
import 'package:fitness/domain/repositories/auth_repository.dart';

class SignInWithGmail {
  final AuthRepository repo;
  SignInWithGmail(this.repo);

  Future<UserEntity?> call(String email) {
    return repo.signInWithGmail(email);
  }
}

