import 'package:fitness/app/ui/auth/domain/repositories/auth_repository.dart';

class DeleteAccount {
  final AuthRepository repo;
  DeleteAccount(this.repo);

  Future<void> call() {
    return repo.deleteAccount();
  }
}

