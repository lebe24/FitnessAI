import 'package:fitness/app/ui/fitness/domain/repositories/user_data_repository.dart';

class GetCompletedDatesUsecase {
  final UserDataRepository repository;

  GetCompletedDatesUsecase(this.repository);

  Future<Set<DateTime>> call(String userId) async {
    return await repository.getCompletedDates(userId);
  }
}

