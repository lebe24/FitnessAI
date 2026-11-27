import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fitness/data/services/video/frame_sampler.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

/// Why an analysis did not produce a result.
enum FormAnalysisFailure {
  /// No connection.
  offline,

  /// The request ran out of time.
  timeout,

  /// The monthly allowance is used up (counted on the device).
  monthlyCap,

  /// Several analyses in a short time.
  rateLimited,

  /// The backend could not get a usable answer from the model.
  couldNotAnalyse,

  /// Not signed in, or the session expired.
  signedOut,

  /// The backend refused the frames.
  badRequest,

  /// The server has no such feature (an older backend): not the user's fault
  /// and not worth retrying until it is updated.
  unavailable,

  /// The user stopped it.
  cancelled,

  other,
}

class FormAnalysisException implements Exception {
  final FormAnalysisFailure failure;
  final String message;

  /// For [FormAnalysisFailure.monthlyCap]: how many of the month's analyses are
  /// used, and the cap (both from the device's own count).
  final int? used;
  final int? cap;

  const FormAnalysisException(this.failure, this.message, {this.used, this.cap});

  /// Retrying could plausibly work.
  bool get canRetry => switch (failure) {
        FormAnalysisFailure.offline ||
        FormAnalysisFailure.timeout ||
        FormAnalysisFailure.couldNotAnalyse ||
        FormAnalysisFailure.rateLimited ||
        FormAnalysisFailure.other =>
          true,
        _ => false,
      };

  /// A fixed label for analytics, with no detail in it.
  String get reason => failure.name;

  @override
  String toString() => 'FormAnalysisException(${failure.name}): $message';
}

class FormAnalysisResult {
  final FormAnalysis analysis;
  final String model;

  const FormAnalysisResult({required this.analysis, required this.model});
}

/// Sends a clip's chosen frames to `POST /api/v1/analysis/form` and reads back
/// the rating. The video itself is never uploaded.
class FormAnalysisService {
  final Dio _dio;

  FormAnalysisService({Dio? dio}) : _dio = dio ?? _defaultDio();

  static Dio _defaultDio() {
    final dio = Dio(BaseOptions(
      baseUrl: Constant.backendUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 60),
      // The model can take most of a minute, twice if it has to retry, and the
      // backend may be waking from idle.
      receiveTimeout: const Duration(seconds: 150),
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        handler.next(options);
      },
    ));
    return dio;
  }

  Future<FormAnalysisResult> analyse({
    required String exerciseName,
    required SampledFrames frames,
    String? cameraHint,
    CancelToken? cancelToken,
    void Function(double sent)? onSendProgress,
  }) async {
    final form = FormData.fromMap({
      'exercise_name': exerciseName,
      'timestamps': jsonEncode(frames.seconds),
      // 0 means the set-up frame; the backend reads that as "no rep".
      'rep_groups': jsonEncode([for (final g in frames.plan.repGroups) g ?? 0]),
      if (cameraHint != null) 'camera_hint': cameraHint,
    });
    for (var i = 0; i < frames.jpegs.length; i++) {
      form.files.add(MapEntry(
        'frames',
        MultipartFile.fromBytes(
          frames.jpegs[i],
          filename: 'frame_$i.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      ));
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/analysis/form',
        data: form,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress == null
            ? null
            : (sent, total) => onSendProgress(total <= 0 ? 0 : sent / total),
      );
      final body = response.data;
      if (body == null) {
        throw const FormAnalysisException(
            FormAnalysisFailure.couldNotAnalyse, 'The server sent nothing back.');
      }
      return FormAnalysisResult(
        analysis: FormAnalysis.fromJson(body),
        model: body['model'] is String ? body['model'] as String : '',
      );
    } on DioException catch (e) {
      throw _translate(e);
    }
  }

  static FormAnalysisException _translate(DioException e) {
    switch (e.type) {
      case DioExceptionType.cancel:
        return const FormAnalysisException(FormAnalysisFailure.cancelled, 'Cancelled');
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const FormAnalysisException(
            FormAnalysisFailure.timeout, 'The analysis took too long.');
      case DioExceptionType.connectionError:
        return const FormAnalysisException(FormAnalysisFailure.offline, 'You are offline.');
      default:
        break;
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;
    final detail = data is Map ? data['detail'] : null;

    if (status == 401 || status == 403) {
      return const FormAnalysisException(
          FormAnalysisFailure.signedOut, 'Please sign in again.');
    }
    if (status == 429) {
      return const FormAnalysisException(
          FormAnalysisFailure.rateLimited, 'Too many analyses at once. Try again in a minute.');
    }
    if (status == 404 || status == 405) {
      return const FormAnalysisException(FormAnalysisFailure.unavailable,
          'Form analysis is not available on the server yet.');
    }
    if (status == 400 || status == 422) {
      return FormAnalysisException(FormAnalysisFailure.badRequest,
          detail is String ? detail : 'The clip could not be sent.');
    }
    if (status == 502 || status == 503 || status == 504) {
      return const FormAnalysisException(
          FormAnalysisFailure.couldNotAnalyse, "Couldn't analyse this clip.");
    }
    return FormAnalysisException(FormAnalysisFailure.other, e.message ?? 'Something went wrong.');
  }
}
