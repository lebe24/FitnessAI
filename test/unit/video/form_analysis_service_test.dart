import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness/data/services/video/form_analysis_service.dart';
import 'package:fitness/data/services/video/frame_sampler.dart';
import 'package:fitness/data/services/video/video_tools.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with [respond], and keeps the request it was given.
class _Adapter implements HttpClientAdapter {
  RequestOptions? seen;
  final Future<ResponseBody> Function(RequestOptions) respond;
  _Adapter(this.respond);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) {
    seen = options;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

SampledFrames _frames({int n = 3}) => SampledFrames(
      FramePlan(
        timesMs: [for (var i = 0; i < n; i++) 1000 + i * 250],
        repGroups: [null, for (var i = 1; i < n; i++) 1],
        reps: const [],
        segments: const [],
        subject: NormRect.full,
      ),
      [for (var i = 0; i < n; i++) Uint8List.fromList([0xff, 0xd8, 0xff, i])],
    );

const _okBody = {
  'exercise': 'conventional deadlift',
  'exercise_matches_request': true,
  'camera_view': 'rear',
  'confidence': 'low',
  'overall_score': 7,
  'stance_score': 8,
  'form_score': null,
  'tempo_score': 5,
  'summary': 'Stable set-up.',
  'reps': {'completed': 3, 'attempts': 4, 'notes': ''},
  'stance': [],
  'form': [],
  'tempo': [],
  'cues': [],
  'good_points': ['Full lockout'],
  'limitations': ['Filmed from behind'],
  'model': 'gpt-6-luna',
  'usage': {'input_tokens': 1000, 'output_tokens': 300},
};

FormAnalysisService _service(_Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
  return FormAnalysisService(dio: dio);
}

Future<FormAnalysisException> _failure(Future<Object?> Function() call) async {
  try {
    await call();
  } on FormAnalysisException catch (e) {
    return e;
  }
  fail('expected a FormAnalysisException');
}

void main() {
  group('a successful analysis', () {
    test('is read into a result', () async {
      final r = await _service(_Adapter((_) async => _json(200, _okBody)))
          .analyse(exerciseName: 'Deadlift', frames: _frames());
      expect(r.analysis.overallScore, 7);
      expect(r.analysis.formScore, isNull);
      expect(r.analysis.cameraView, CameraView.rear);
      expect(r.model, 'gpt-6-luna');
    });

    test('sends the frames and what the backend needs to read them', () async {
      final adapter = _Adapter((_) async => _json(200, _okBody));
      await _service(adapter)
          .analyse(exerciseName: 'Deadlift', frames: _frames(n: 3), cameraHint: 'side');
      final o = adapter.seen!;
      expect(o.method, 'POST');
      expect(o.path, '/api/v1/analysis/form');
      final form = o.data as FormData;
      final fields = {for (final f in form.fields) f.key: f.value};
      expect(fields['exercise_name'], 'Deadlift');
      expect(fields['camera_hint'], 'side');
      expect(jsonDecode(fields['timestamps']!), [1.0, 1.25, 1.5]);
      expect(jsonDecode(fields['rep_groups']!), [0, 1, 1], reason: 'set-up frame is 0');
      expect(form.files.where((f) => f.key == 'frames'), hasLength(3));
      expect(form.files.first.value.contentType.toString(), 'image/jpeg');
    });

    test('sends no camera hint unless there is one', () async {
      final adapter = _Adapter((_) async => _json(200, _okBody));
      await _service(adapter).analyse(exerciseName: 'x', frames: _frames());
      expect((adapter.seen!.data as FormData).fields.map((f) => f.key), isNot(contains('camera_hint')));
    });

    test('a result that is missing parts still reads', () async {
      final r = await _service(_Adapter((_) async => _json(200, {'camera_view': 'side'})))
          .analyse(exerciseName: 'x', frames: _frames());
      expect(r.analysis.overallScore, isNull);
    });
  });

  group('failures', () {
    Future<FormAnalysisException> failWith(Future<ResponseBody> Function(RequestOptions) r) =>
        _failure(() => _service(_Adapter(r)).analyse(exerciseName: 'x', frames: _frames()));

    test('a rate limit (429) is retryable; the monthly cap is not the server\'s business', () async {
      final e = await failWith((_) async => _json(429, {
            'detail': {'code': 'rate_limited', 'message': 'Slow down'}
          }));
      expect(e.failure, FormAnalysisFailure.rateLimited);
      expect(e.canRetry, isTrue);
    });

    test('a model failure (502) is retryable', () async {
      final e = await failWith((_) async => _json(502, {'detail': 'nope'}));
      expect(e.failure, FormAnalysisFailure.couldNotAnalyse);
      expect(e.canRetry, isTrue);
    });

    test('404 (a backend without the feature) is "unavailable", not a vague failure', () async {
      final e = await failWith((_) async => _json(404, {'detail': 'Not Found'}));
      expect(e.failure, FormAnalysisFailure.unavailable);
      expect(e.canRetry, isFalse);
    });

    test('401 means sign in again', () async {
      final e = await failWith((_) async => _json(401, {'detail': 'x'}));
      expect(e.failure, FormAnalysisFailure.signedOut);
      expect(e.canRetry, isFalse);
    });

    test('400 carries the backend message', () async {
      final e = await failWith((_) async => _json(400, {'detail': 'Frames must be JPEG images.'}));
      expect(e.failure, FormAnalysisFailure.badRequest);
      expect(e.message, 'Frames must be JPEG images.');
    });

    test('no connection is "offline"', () async {
      final e = await failWith((o) async => throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError));
      expect(e.failure, FormAnalysisFailure.offline);
      expect(e.canRetry, isTrue);
    });

    test('running out of time is a timeout', () async {
      final e = await failWith((o) async => throw DioException(
          requestOptions: o, type: DioExceptionType.receiveTimeout));
      expect(e.failure, FormAnalysisFailure.timeout);
    });

    test('anything else is "other" and retryable', () async {
      final e = await failWith((_) async => _json(500, {'detail': 'boom'}));
      expect(e.failure, FormAnalysisFailure.other);
      expect(e.canRetry, isTrue);
    });

    test('a failure reports a fixed label, never the detail', () async {
      final e = await failWith((_) async => _json(400, {'detail': 'secret details'}));
      expect(e.reason, 'badRequest');
    });

    test('cancelling is reported as cancelled', () async {
      final token = CancelToken();
      final adapter = _Adapter((o) async {
        token.cancel();
        throw DioException(requestOptions: o, type: DioExceptionType.cancel);
      });
      final e = await _failure(() =>
          _service(adapter).analyse(exerciseName: 'x', frames: _frames(), cancelToken: token));
      expect(e.failure, FormAnalysisFailure.cancelled);
    });
  });
}
