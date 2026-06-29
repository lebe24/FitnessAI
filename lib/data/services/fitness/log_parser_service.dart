import 'package:dio/dio.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParsedSet {
  final double? weightKg;
  final int? reps;
  const ParsedSet({this.weightKg, this.reps});
}

class LogParserService {
  late final Dio _dio;

  LogParserService() {
    _dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
    ));
  }

  /// Calls POST /api/v1/logs/parse-speech and returns one [ParsedSet] per set.
  Future<List<ParsedSet>> parseSpeech({
    required String transcript,
    required int numSets,
  }) async {
    final response = await _dio.post('/api/v1/logs/parse-speech', data: {
      'transcript': transcript,
      'num_sets': numSets,
    });
    final sets = (response.data['sets'] as List).map((s) {
      final w = s['weight_kg'];
      final r = s['reps'];
      return ParsedSet(
        weightKg: w != null ? (w as num).toDouble() : null,
        reps: r != null ? (r as num).toInt() : null,
      );
    }).toList();
    return sets;
  }
}
