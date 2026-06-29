import 'package:fitness/ui/core/di.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UserDataRemoteDataSource {
  /// Get user streak from user_data table
  Future<int> getUserStreak(String userId);

  /// Get all user_data records for a user
  Future<List<Map<String, dynamic>>> getUserData(String userId);

  /// Get completed dates for a user (dates where workouts were completed)
  Future<Set<DateTime>> getCompletedDates(String userId);

  /// Check if workout is completed for a specific date
  Future<bool> isWorkoutCompletedForDate(String userId, DateTime date);

  /// Update user_data record: increment streak and append to date_n_duration array
  Future<void> updateWorkoutCompletion({
    required String userId,
    required double duration,
    required DateTime date,
  });
}

class UserDataRemoteDataSourceImpl implements UserDataRemoteDataSource {
  final client = sl<SupabaseClient>();

  @override
  Future<int> getUserStreak(String userId) async {
    try {
      final response = await client
          .from('user_data')
          .select('streak')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final latestRecord = response.first;
        return (latestRecord['streak'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      throw Exception('Failed to get user streak: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserData(String userId) async {
    try {
      final response = await client
          .from('user_data')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.cast<Map<String, dynamic>>();
        } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  @override
  Future<Set<DateTime>> getCompletedDates(String userId) async {
    try {
      // Get the user's record (should be single row per user)
      final response = await client
          .from('user_data')
          .select('date_n_duration, date')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      final dates = <DateTime>{};
      if (response.isNotEmpty) {
        final record = response.first;
        
        // Extract dates from date_n_duration array
        if (record['date_n_duration'] != null && record['date_n_duration'] is List) {
          final dateNDurationArray = record['date_n_duration'] as List;
          for (var entry in dateNDurationArray) {
            if (entry is Map && entry['date'] != null) {
              try {
                final entryDate = DateTime.parse(entry['date']);
                // Normalize to just year/month/day
                final normalizedDate = DateTime(entryDate.year, entryDate.month, entryDate.day);
                dates.add(normalizedDate);
              } catch (e) {
                // Skip invalid dates
                continue;
              }
            }
          }
        }
        
        // Also check the date column
        if (record['date'] != null) {
          try {
            // date column is type 'date' which should be in format 'YYYY-MM-DD'
            final dateStr = record['date'] as String;
            final dateParts = dateStr.split('-');
            if (dateParts.length == 3) {
              final dateFromColumn = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
              );
              final normalizedDate = DateTime(dateFromColumn.year, dateFromColumn.month, dateFromColumn.day);
              dates.add(normalizedDate);
            }
          } catch (e) {
            // Skip invalid date format
          }
        }
      }
      return dates;
    } catch (e) {
      throw Exception('Failed to get completed dates: $e');
    }
  }

  @override
  Future<bool> isWorkoutCompletedForDate(String userId, DateTime date) async {
    try {
      // Normalize the workout date
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final dateStr = '${normalizedDate.year}-${normalizedDate.month.toString().padLeft(2, '0')}-${normalizedDate.day.toString().padLeft(2, '0')}';

      // Get user's record and check date column and date_n_duration array
      final response = await client
          .from('user_data')
          .select('date, date_n_duration')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final record = response.first;
        
        // Check if date column matches
        if (record['date'] != null) {
          final recordDateStr = record['date'] as String;
          if (recordDateStr == dateStr) {
            return true;
          }
        }
        
        // Check if date exists in date_n_duration array
        if (record['date_n_duration'] != null && record['date_n_duration'] is List) {
          final dateNDurationArray = record['date_n_duration'] as List;
          for (var entry in dateNDurationArray) {
            if (entry is Map && entry['date'] != null) {
              try {
                final entryDate = DateTime.parse(entry['date']);
                final entryNormalized = DateTime(entryDate.year, entryDate.month, entryDate.day);
                if (entryNormalized.year == normalizedDate.year &&
                    entryNormalized.month == normalizedDate.month &&
                    entryNormalized.day == normalizedDate.day) {
                  return true;
                }
              } catch (e) {
                continue;
              }
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      throw Exception('Failed to check workout completion: $e');
    }
  }

  @override
  Future<void> updateWorkoutCompletion({
    required String userId,
    required double duration,
    required DateTime date,
  }) async {
    try {
      // Format date as date string (YYYY-MM-DD format)
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final dateStr = '${normalizedDate.year}-${normalizedDate.month.toString().padLeft(2, '0')}-${normalizedDate.day.toString().padLeft(2, '0')}';
      
      // Check if user has an existing record (should be one row per user)
      final existingResponse = await client
          .from('user_data')
          .select('id, streak, date_n_duration, date')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      // Prepare the new date_n_duration entry
      final newEntry = {
        'date': date.toIso8601String(),
        'duration': duration,
      };

      if (existingResponse.isNotEmpty) {
        // Found existing record - UPDATE it using user_id
        final existingRecord = existingResponse.first;
        final currentStreak = (existingRecord['streak'] as int?) ?? 0;
        
        // Increment streak for each completed workout
        final newStreak = currentStreak + 1;
        
        // Get existing date_n_duration array
        List<dynamic> dateNDurationArray = [];
        if (existingRecord['date_n_duration'] != null && existingRecord['date_n_duration'] is List) {
          dateNDurationArray = List<dynamic>.from(existingRecord['date_n_duration']);
        }
        
        // Append new entry to the array
        dateNDurationArray.add(newEntry);

        // Update the existing record by user_id (always update the same row)
        await client
            .from('user_data')
            .update({
              'streak': newStreak,
              'date_n_duration': dateNDurationArray,
              'date': dateStr, // Update date column with the workout date
            })
            .eq('user_id', userId) // Update using user_id
            .select();
      } else {
        // No existing record - create new one with streak = 1
        await client
            .from('user_data')
            .insert({
              'user_id': userId,
              'streak': 1,
              'duration': duration,
              'date': dateStr,
              'date_n_duration': [newEntry],
            })
            .select();
      }
    } catch (e) {
      throw Exception('Failed to update workout completion: $e');
    }
  }
}

