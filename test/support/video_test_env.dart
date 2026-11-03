import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/data/services/video/form_analysis_runner.dart';
import 'package:fitness/data/services/video/form_analysis_service.dart';
import 'package:fitness/data/services/video/frame_sampler.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'synthetic_clip.dart';

/// A form-analysis service that answers from a script, for the runner.
class ScriptedFormService extends FormAnalysisService {
  ScriptedFormService() : super(dio: Dio());

  FormAnalysisException? error;

  /// When set, the analysis waits here, so a test can look at the "analysing"
  /// state. It honours cancelling, like the real request does.
  Completer<void>? gate;
  FormAnalysis analysis = const FormAnalysis(overallScore: 7, confidence: Confidence.high);

  @override
  Future<FormAnalysisResult> analyse({
    required String exerciseName,
    required SampledFrames frames,
    String? cameraHint,
    CancelToken? cancelToken,
    void Function(double sent)? onSendProgress,
  }) async {
    onSendProgress?.call(1);
    if (gate != null) {
      await gate!.future;
      if (cancelToken?.isCancelled ?? false) {
        throw const FormAnalysisException(FormAnalysisFailure.cancelled, 'Cancelled');
      }
    }
    if (error != null) throw error!;
    return FormAnalysisResult(analysis: analysis, model: 'm');
  }
}

/// A real storage and runner on a temp folder and an in-memory-ish Hive, with
/// the platform and the network faked. One per test.
class VideoTestEnv {
  final Directory docs;
  final Directory scratch;
  final ExerciseVideoStorage storage;
  final FakeVideoTools tools;
  final ScriptedFormService service;
  final FormAnalysisRunner runner;
  var _n = 0;

  VideoTestEnv._(this.docs, this.scratch, this.storage, this.tools, this.service, this.runner);

  static Future<VideoTestEnv> create() async {
    final docs = Directory.systemTemp.createTempSync('vt_docs');
    final scratch = Directory.systemTemp.createTempSync('vt_scratch');
    Hive.init(Directory.systemTemp.createTempSync('vt_hive').path);
    await Hive.openBox<Map>(ExerciseVideoStorage.boxName);
    final storage = ExerciseVideoStorage(documents: () async => docs);
    final tools = FakeVideoTools(
        clip: SyntheticClip(20000, bursts: [(5000, 5750), (9000, 9750)]));
    final service = ScriptedFormService();
    final runner = FormAnalysisRunner(storage: storage, tools: tools, service: service);
    return VideoTestEnv._(docs, scratch, storage, tools, service, runner);
  }

  /// Save a video (needs real file IO: call inside `tester.runAsync`).
  Future<ExerciseVideo> add(
    String exercise, {
    List<String> muscles = const [],
    DateTime? at,
    FormAnalysis? analysis,
    int durationMs = 42000,
  }) async {
    final id = 'v${_n++}';
    final video = File(p.join(scratch.path, '$id.mp4'))..writeAsBytesSync(List.filled(64, 1));
    final thumb = File(p.join(scratch.path, '$id.jpg'))..writeAsBytesSync([0xff, 0xd8]);
    var saved = await storage.save(
      id: id,
      video: video,
      thumbnail: thumb,
      durationMs: durationMs,
      exerciseName: exercise,
      muscles: muscles,
      recordedAt: at ?? DateTime(2026, 11, 1, 9),
    );
    if (analysis != null) {
      saved = (await storage.setAnalysis(id, analysis, model: 'm'))!;
    }
    return saved;
  }

  Future<void> dispose() async {
    await Hive.close();
    for (final d in [docs, scratch]) {
      if (d.existsSync()) d.deleteSync(recursive: true);
    }
  }
}
