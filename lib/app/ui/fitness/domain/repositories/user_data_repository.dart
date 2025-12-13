abstract class UserDataRepository {
  Future<int> getUserStreak(String userId);
  Future<List<Map<String, dynamic>>> getUserData(String userId);
  Future<Set<DateTime>> getCompletedDates(String userId);
  Future<bool> isWorkoutCompletedForDate(String userId, DateTime date);
  Future<void> updateWorkoutCompletion({
    required String userId,
    required double duration,
    required DateTime date,
  });
}

