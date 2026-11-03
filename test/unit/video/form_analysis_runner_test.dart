import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/data/services/video/form_analysis_runner.dart';
import 'package:fitness/data/services/video/form_analysis_service.dart';
import 'package:fitness/data/services/video/form_analysis_usage.dart';
import 'package:fitness/data/services/video/frame_sampler.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import '../../support/synthetic_clip.dart';

class _FakeService extends FormAnalysisService {
  _FakeService() : super(dio: Dio());

  Completer<FormAnalysisResult>? gate;
  FormAnalysisException? error;
  int calls = 0;
  SampledFrames? lastFrames;
  String? lastName;
  CancelToken? lastToken;
  void Function(double)? lastProgress;

  FormAnalysis analysis = const FormAnalysis(
    overallScore: 7,
    stanceScore: 8,
    tempoScore: 5,
    cameraView: CameraView.side,
    confidence: Confidence.high,
    limitations: ['x'],
  );

  @override
  Future<FormAnalysisResult> analyse({
    required String exerciseName,
    required SampledFrames frames,
    String? cameraHint,
    CancelToken? cancelToken,
    void Function(double sent)? onSendProgress,
  }) async {
    calls++;
    lastFrames = frames;
    lastName = exerciseName;
    lastToken = cancelToken;
    lastProgress = onSendProgress;
    onSendProgress?.call(1);
    if (gate != null) return gate!.future;
    if (error != null) throw error!;
    return FormAnalysisResult(analysis: analysis, model: 'gpt-6-luna');
  }
}

void main() {
  late Directory docs;
  late ExerciseVideoStorage storage;
  late FakeVideoTools tools;
  late _FakeService service;
  late FormAnalysisRunner runner;
  late ExerciseVideo video;

  Future<ExerciseVideo> addVideo(String id) async {
    final src = File(p.join(Directory.systemTemp.path, '$id.mp4'))..writeAsBytesSync([1, 2, 3]);
    final thumb = File(p.join(Directory.systemTemp.path, '$id.jpg'))..writeAsBytesSync([1]);
    return storage.save(
      id: id,
      video: src,
      thumbnail: thumb,
      durationMs: 20000,
      exerciseName: 'Deadlift',
      muscles: const ['hamstring'],
    );
  }

  Future<AnalysisJob> finish(AnalysisJob job) async {
    while (job.isRunning) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return job;
  }

  setUp(() async {
    docs = Directory.systemTemp.createTempSync('run_docs');
    Hive.init(Directory.systemTemp.createTempSync('run_hive').path);
    await Hive.openBox<Map>(ExerciseVideoStorage.boxName);
    storage = ExerciseVideoStorage(documents: () async => docs);
    tools = FakeVideoTools(
        clip: SyntheticClip(20000, bursts: [(5000, 5750), (9000, 9750), (13000, 13750)]));
    service = _FakeService();
    runner = FormAnalysisRunner(storage: storage, tools: tools, service: service);
    video = await addVideo('v1');
  });

  tearDown(() async {
    await Hive.close();
    if (docs.existsSync()) docs.deleteSync(recursive: true);
  });

  test('analyses a saved video and stores the result with it', () async {
    final job = await finish(runner.start(video));
    expect(job.phase, AnalysisPhase.done);
    expect(job.result!.overallScore, 7);

    expect(service.calls, 1);
    expect(service.lastName, 'Deadlift');
    expect(service.lastFrames!.count, lessThanOrEqualTo(12));
    expect(tools.grayCalls, 1, reason: 'one pass for the motion map');
    expect(tools.cropCalls, 1, reason: 'then only the chosen frames are encoded');

    final stored = (await storage.byId('v1'))!;
    expect(stored.analysis!.overallScore, 7);
    expect(stored.analysisModel, 'gpt-6-luna');
    expect(stored.analysedAt, isNotNull);
  });

  test('counts each successful analysis on the device', () async {
    await finish(runner.start(video));
    expect((runner.used, runner.cap), (1, 30));
    expect(await runner.usage.usedThisMonth(), 1);

    runner.dismiss('v1');
    await finish(runner.start(video));
    expect(runner.used, 2);
  });

  test('walks through the phases', () async {
    service.gate = Completer();
    final phases = <AnalysisPhase>[];
    final job = runner.start(video);
    job.addListener(() => phases.add(job.phase));
    while (job.phase != AnalysisPhase.analysing) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(runner.busy, isTrue);
    expect(runner.running, same(job));
    service.gate!.complete(
        FormAnalysisResult(analysis: service.analysis, model: 'm'));
    await finish(job);
    expect(phases, containsAllInOrder([AnalysisPhase.uploading, AnalysisPhase.analysing, AnalysisPhase.done]));
    expect(runner.busy, isFalse);
  });

  test('starting the same video again joins the running analysis', () async {
    service.gate = Completer();
    final a = runner.start(video);
    final b = runner.start(video);
    expect(b, same(a));
    service.gate!.complete(
        FormAnalysisResult(analysis: service.analysis, model: 'm'));
    await finish(a);
    expect(service.calls, 1);
  });

  group('when it fails', () {
    test('the video is untouched and the job says why', () async {
      service.error = const FormAnalysisException(FormAnalysisFailure.couldNotAnalyse, 'bad');
      final job = await finish(runner.start(video));
      expect(job.phase, AnalysisPhase.failed);
      expect(job.error!.failure, FormAnalysisFailure.couldNotAnalyse);
      expect((await storage.byId('v1'))!.isAnalysed, isFalse);
      expect(File(p.join(docs.path, video.filePath)).existsSync(), isTrue);
    });

    test('a retry starts clean and can succeed', () async {
      service.error = const FormAnalysisException(FormAnalysisFailure.timeout, 'slow');
      await finish(runner.start(video));
      runner.dismiss('v1');
      expect(runner.jobFor('v1'), isNull);

      service.error = null;
      final job = await finish(runner.start(video));
      expect(job.phase, AnalysisPhase.done);
      expect((await storage.byId('v1'))!.isAnalysed, isTrue);
    });

    test('a failed analysis is not counted', () async {
      service.error = const FormAnalysisException(FormAnalysisFailure.couldNotAnalyse, 'bad');
      await finish(runner.start(video));
      expect(await runner.usage.usedThisMonth(), 0);
    });

    test('at the monthly cap nothing is sent and the video is untouched', () async {
      for (var i = 0; i < FormAnalysisUsage.monthlyCap; i++) {
        await runner.usage.record();
      }
      final job = await finish(runner.start(video));
      expect(job.phase, AnalysisPhase.failed);
      expect(job.error!.failure, FormAnalysisFailure.monthlyCap);
      expect((job.error!.used, job.error!.cap), (30, 30));
      expect(service.calls, 0, reason: 'no frames leave the phone over the cap');
      expect(tools.grayCalls, 0, reason: 'and no work is done');
      expect((await storage.byId('v1'))!.isAnalysed, isFalse);
      expect(await runner.usage.usedThisMonth(), 30, reason: 'the refusal is not counted');
    });

    test('one below the cap still runs, and then the next is refused', () async {
      for (var i = 0; i < FormAnalysisUsage.monthlyCap - 1; i++) {
        await runner.usage.record();
      }
      expect((await finish(runner.start(video))).phase, AnalysisPhase.done);
      runner.dismiss('v1');
      expect((await finish(runner.start(video))).error!.failure, FormAnalysisFailure.monthlyCap);
    });

    test('a missing file fails cleanly', () async {
      File(p.join(docs.path, video.filePath)).deleteSync();
      final job = await finish(runner.start(video));
      expect(job.phase, AnalysisPhase.failed);
      expect(service.calls, 0);
    });

    test('a video the platform cannot read fails cleanly', () async {
      tools.infoError = Exception('boom');
      final job = await finish(runner.start(video));
      expect(job.phase, AnalysisPhase.failed);
      expect(service.calls, 0);
    });

    test('a failed analysis does not block the next one', () async {
      service.error = const FormAnalysisException(FormAnalysisFailure.timeout, 'slow');
      await finish(runner.start(video));
      final other = await addVideo('v2');
      service.error = null;
      final job = await finish(runner.start(other));
      expect(job.phase, AnalysisPhase.done);
    });
  });

  group('cancelling', () {
    test('while waiting for the model stops the request', () async {
      service.gate = Completer();
      final job = runner.start(video);
      while (job.phase != AnalysisPhase.analysing) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      runner.cancel('v1');
      expect(service.lastToken!.isCancelled, isTrue);
      service.gate!.completeError(
          const FormAnalysisException(FormAnalysisFailure.cancelled, 'Cancelled'));
      await finish(job);
      expect(job.phase, AnalysisPhase.cancelled);
      expect((await storage.byId('v1'))!.isAnalysed, isFalse);
    });

    test('cancelling something that is not running does nothing', () async {
      runner.cancel('nope');
      await finish(runner.start(video));
      runner.cancel('v1');
      expect(runner.jobFor('v1')!.phase, AnalysisPhase.done);
    });
  });

  test('a result that arrives after the video was deleted does not bring it back', () async {
    service.gate = Completer();
    final job = runner.start(video);
    while (job.phase != AnalysisPhase.analysing) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await storage.delete('v1');
    service.gate!.complete(
        FormAnalysisResult(analysis: service.analysis, model: 'm'));
    await finish(job);
    expect(await storage.byId('v1'), isNull);
    expect(await storage.all(), isEmpty);
  });

  group('when the frames were a guess', () {
    test('a clip with no clear movement is marked low confidence on the result', () async {
      tools = FakeVideoTools(clip: SyntheticClip(20000));
      runner = FormAnalysisRunner(storage: storage, tools: tools, service: service);
      final job = await finish(runner.start(video));
      expect(job.phase, AnalysisPhase.done);
      expect(job.result!.confidence, Confidence.low);
      expect(job.result!.limitations, contains('No clear movement was found.'));
      expect(service.lastFrames!.count, 8, reason: 'evenly spaced fallback');
    });

    test('a clear clip keeps the model\'s own confidence', () async {
      final job = await finish(runner.start(video));
      expect(job.result!.confidence, Confidence.high);
      expect(job.result!.limitations, ['x']);
    });
  });
}
