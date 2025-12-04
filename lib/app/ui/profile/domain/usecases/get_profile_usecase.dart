import 'package:fitness/app/ui/profile/domain/entities/profile_entity.dart';
import 'package:fitness/app/ui/profile/domain/repositories/profile_repository.dart';

class GetProfileUseCase {
  final ProfileRepository repository;

  GetProfileUseCase(this.repository);

  Future<ProfileEntity> call() {
    return repository.getProfile();
  }
}

