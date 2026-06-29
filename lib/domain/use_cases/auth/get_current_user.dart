import 'package:fitness/domain/models/user.dart';
import 'package:fitness/domain/repositories/auth_repository.dart';

class GetCurrentUser {
  final AuthRepository repo;
  GetCurrentUser(this.repo);

  UserEntity? call() {
    return repo.getCurrentUser();
  }
}

















