import 'package:fitness/app/ui/fitness/data/datasources/user_data_remote_datasource.dart';
import 'package:fitness/app/ui/fitness/domain/repositories/user_data_repository.dart';

class UserDataRepositoryImpl implements UserDataRepository {
  final UserDataRemoteDataSource remoteDataSource;

  UserDataRepositoryImpl(this.remoteDataSource);

  @override
  Future<int> getUserStreak(String userId) async {
    return await remoteDataSource.getUserStreak(userId);
  }

  @override
  Future<List<Map<String, dynamic>>> getUserData(String userId) async {
    return await remoteDataSource.getUserData(userId);
  }

  @override
  Future<Set<DateTime>> getCompletedDates(String userId) async {
    return await remoteDataSource.getCompletedDates(userId);
  }

  @override
  Future<bool> isWorkoutCompletedForDate(String userId, DateTime date) async {
    return await remoteDataSource.isWorkoutCompletedForDate(userId, date);
  }

  @override
  Future<void> updateWorkoutCompletion({
    required String userId,
    required double duration,
    required DateTime date,
  }) async {
    return await remoteDataSource.updateWorkoutCompletion(
      userId: userId,
      duration: duration,
      date: date,
    );
  }
}

