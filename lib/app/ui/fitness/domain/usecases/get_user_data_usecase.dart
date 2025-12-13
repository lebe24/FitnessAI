import 'package:fitness/app/ui/fitness/domain/repositories/user_data_repository.dart';

class GetUserDataUsecase {
  final UserDataRepository repository;

  GetUserDataUsecase(this.repository);

  Future<List<Map<String, dynamic>>> call(String userId) async {
    return await repository.getUserData(userId);
  }
}

