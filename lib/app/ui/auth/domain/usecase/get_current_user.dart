import 'package:fitness/app/ui/auth/domain/entities/user_entity.dart';
import 'package:fitness/app/ui/auth/domain/repositories/auth_repository.dart';

class GetCurrentUser {
  final AuthRepository repo;
  GetCurrentUser(this.repo);

  UserEntity? call() {
    return repo.getCurrentUser();
  }
}
















