import 'package:fitness/app/ui/fitness/domain/repositories/user_data_repository.dart';

class UpdateWorkoutCompletionUsecase {
  final UserDataRepository repository;

  UpdateWorkoutCompletionUsecase(this.repository);

  Future<void> call({
    required String userId,
    required double duration,
    required DateTime date,
  }) async {
    return await repository.updateWorkoutCompletion(
      userId: userId,
      duration: duration,
      date: date,
    );
  }
}

