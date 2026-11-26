import 'package:dio/dio.dart';
import 'package:fitness/data/models/body/body_json.dart';
import 'package:fitness/domain/body/body_advice.dart';
import 'package:fitness/domain/body/body_models.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The backend's goal, weight, measurement and advice routes.
abstract class BodyTrackingRemote {
  Future<FitnessGoal?> getGoal();
  Future<FitnessGoal> putGoal(FitnessGoal goal);
  Future<void> deleteGoal();
  Future<List<BodyWeightEntry>> listWeights({DateTime? since});
  Future<BodyWeightEntry> postWeight(BodyWeightEntry entry);
  Future<void> deleteWeight(String id);
  Future<List<BodyMeasurement>> listMeasurements({DateTime? since});
  Future<void> postMeasurements(List<BodyMeasurement> entries);
  Future<void> deleteMeasurement(String id);

  /// Writes entries made offline in one request. Safe to repeat.
  Future<void> sync({
    required List<BodyWeightEntry> weights,
    required List<BodyMeasurement> measurements,
  });
  Future<void> postScan(Map<String, dynamic> scan);
  Future<BodyAdvice> advise(AdviceRequest request);
}

class DioBodyTrackingRemote implements BodyTrackingRemote {
  late final Dio _dio;

  DioBodyTrackingRemote({Dio? dio}) {
    _dio = dio ?? _build();
  }

  static Dio _build() {
    final dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 45), // advice can take a while
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
    ));
    return dio;
  }

  /// Runs [call], turning transport and HTTP failures into a
  /// [BodyTrackingException] the screens can word for the user.
  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = e.response?.data is Map ? (e.response!.data as Map)['detail'] : null;
      final code = detail is Map ? detail['code'] : null;
      if (status == 403 && code == 'premium_required') {
        throw const BodyTrackingException(BodyTrackingError.premiumRequired);
      }
      if (status == 429) throw const BodyTrackingException(BodyTrackingError.rateLimited);
      if (status == null) throw BodyTrackingException(BodyTrackingError.offline, e.message ?? '');
      throw BodyTrackingException(BodyTrackingError.server, 'HTTP $status');
    }
  }

  static String _d(DateTime d) => BodyJson.day(d);

  @override
  Future<FitnessGoal?> getGoal() => _run(() async {
        final r = await _dio.get('/api/v1/goals/active');
        return r.data is Map ? BodyJson.goalFrom(Map<String, dynamic>.from(r.data as Map)) : null;
      });

  @override
  Future<FitnessGoal> putGoal(FitnessGoal goal) => _run(() async {
        final r = await _dio.put('/api/v1/goals/active', data: BodyJson.goalTo(goal));
        return BodyJson.goalFrom(Map<String, dynamic>.from(r.data as Map));
      });

  @override
  Future<void> deleteGoal() => _run(() => _dio.delete('/api/v1/goals/active'));

  @override
  Future<List<BodyWeightEntry>> listWeights({DateTime? since}) => _run(() async {
        final r = await _dio.get('/api/v1/body/weight',
            queryParameters: {if (since != null) 'since': _d(since), 'limit': 2000});
        return [for (final j in r.data as List) BodyJson.weightFrom(Map<String, dynamic>.from(j as Map))];
      });

  @override
  Future<BodyWeightEntry> postWeight(BodyWeightEntry entry) => _run(() async {
        final r = await _dio.post('/api/v1/body/weight', data: BodyJson.weightTo(entry));
        return BodyJson.weightFrom(Map<String, dynamic>.from(r.data as Map));
      });

  @override
  Future<void> deleteWeight(String id) => _run(() => _dio.delete('/api/v1/body/weight/$id'));

  @override
  Future<List<BodyMeasurement>> listMeasurements({DateTime? since}) => _run(() async {
        final r = await _dio.get('/api/v1/body/measurements',
            queryParameters: {if (since != null) 'since': _d(since), 'limit': 5000});
        return [
          for (final j in r.data as List)
            if (BodyJson.measurementFrom(Map<String, dynamic>.from(j as Map)) != null)
              BodyJson.measurementFrom(Map<String, dynamic>.from(j))!
        ];
      });

  @override
  Future<void> postMeasurements(List<BodyMeasurement> entries) => _run(
      () => _dio.post('/api/v1/body/measurements', data: [for (final m in entries) BodyJson.measurementTo(m)]));

  @override
  Future<void> deleteMeasurement(String id) => _run(() => _dio.delete('/api/v1/body/measurements/$id'));

  @override
  Future<void> sync({
    required List<BodyWeightEntry> weights,
    required List<BodyMeasurement> measurements,
  }) =>
      _run(() => _dio.post('/api/v1/body/sync', data: {
            'weights': [for (final w in weights) BodyJson.weightTo(w)],
            'measurements': [for (final m in measurements) BodyJson.measurementTo(m)],
          }));

  @override
  Future<void> postScan(Map<String, dynamic> scan) =>
      _run(() => _dio.post('/api/v1/body/scans', data: scan));

  @override
  Future<BodyAdvice> advise(AdviceRequest request) => _run(() async {
        final r = await _dio.post('/api/v1/goals/advice', data: BodyJson.adviceRequestTo(request));
        return BodyJson.adviceFrom(Map<String, dynamic>.from(r.data as Map));
      });
}
