
import 'package:fitness/app/ui/auth/domain/repositories/auth_repository.dart';

class SignOut {
  final AuthRepository repo;
  SignOut(this.repo);

  Future<void> call() {
    return repo.signOut();
  }
}
