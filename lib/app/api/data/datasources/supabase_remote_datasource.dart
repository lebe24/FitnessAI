import 'dart:math';

import 'package:fitness/app/core/di.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupabaseRemoteDataSource {
  Future<Map<String, dynamic>?> getMotivation(String gender);
}

class SupabaseRemoteDataSourceImpl implements SupabaseRemoteDataSource {
  final client = sl<SupabaseClient>();

  

  @override
  Future<Map<String, dynamic>?> getMotivation(String gender) async {
    try {
      // Normalize gender to match database format (capitalize first letter)
      final normalizedGender = gender.isNotEmpty
          ? '${gender[0].toUpperCase()}${gender.substring(1).toLowerCase()}'
          : gender;

      debugPrint('Fetching motivation for gender: $normalizedGender (original: $gender)');

      // Try with normalized gender first (e.g., "Male", "Female")
      var response = await client
          .from('motivation_content')
          .select('*')
          .eq('gender', normalizedGender);

      // Convert to List if needed
      List<dynamic> records = response is List ? response : [];
      
      debugPrint('Initial query returned ${records.length} records for gender: $normalizedGender');

      // If no results, try with original gender value
      if (records.isEmpty && normalizedGender != gender) {
        debugPrint('Trying with original gender: $gender');
        final altResponse = await client
            .from('motivation_content')
            .select('*')
            .eq('gender', gender);
        records = altResponse is List ? altResponse : [];
      }

      // If still no results, try case-insensitive by fetching all and filtering
      if (records.isEmpty) {
        debugPrint('Trying to fetch all records and filter...');
        final allRecords = await client
            .from('motivation_content')
            .select('*');

        if (allRecords != null && allRecords is List && allRecords.isNotEmpty) {
          final filtered = (allRecords as List).where((record) {
            final recordGender = (record['gender'] as String? ?? '').toLowerCase();
            return recordGender == gender.toLowerCase() ||
                recordGender == normalizedGender.toLowerCase();
          }).toList();

          if (filtered.isNotEmpty) {
            records = filtered;
            debugPrint('Found ${filtered.length} records after filtering');
          }
        }
      }

      if (records.isEmpty) {
        debugPrint('No motivation content found for gender: $gender');
        return null;
      }

      debugPrint('Found ${records.length} records');

      // Randomly select one record
      final random = Random();
      final randomIndex = random.nextInt(records.length);
      final selected = records[randomIndex] as Map<String, dynamic>?;
      
      debugPrint('Selected record ID: ${selected?['id']}, photo_tone: ${selected?['photo_tone']}');
      return selected;
    } catch (e) {
      debugPrint('Error fetching motivation: $e');
      rethrow;
    }
  }
}

