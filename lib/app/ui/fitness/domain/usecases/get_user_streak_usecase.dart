import 'package:fitness/app/ui/fitness/domain/repositories/user_data_repository.dart';

class GetUserStreakUsecase {
  final UserDataRepository repository;

  GetUserStreakUsecase(this.repository);

  Future<int> call(String userId) async {
    return await repository.getUserStreak(userId);
  }
}

