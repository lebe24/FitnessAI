import 'package:dio/dio.dart';
import 'package:fitness/data/services/analytics/video_analytics.dart';
import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/data/services/video/form_analysis_service.dart';
import 'package:fitness/data/services/video/form_analysis_usage.dart';
import 'package:fitness/data/services/video/frame_sampler.dart';
import 'package:fitness/data/services/video/video_tools.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:flutter/foundation.dart';

enum AnalysisPhase {
  /// Choosing frames on the device.
  sampling,

  /// Sending them.
  uploading,

  /// Waiting for the model.
  analysing,

  done,
  failed,
  cancelled,
}

/// One analysis in flight (or just finished). The cards in the video list watch
/// it, and it outlives the screen that started it, so leaving the page does not
/// lose the work.
class AnalysisJob extends ChangeNotifier {
  final String videoId;
  final CancelToken _cancel = CancelToken();

  AnalysisPhase _phase = AnalysisPhase.sampling;
  FormAnalysisException? _error;
  FormAnalysis? _result;

  AnalysisJob(this.videoId);

  AnalysisPhase get phase => _phase;
  FormAnalysisException? get error => _error;
  FormAnalysis? get result => _result;

  bool get isRunning =>
      _phase == AnalysisPhase.sampling ||
      _phase == AnalysisPhase.uploading ||
      _phase == AnalysisPhase.analysing;

  bool get isCancelled => _cancel.isCancelled;

  void _set(AnalysisPhase phase) {
    if (_phase == phase) return;
    _phase = phase;
    notifyListeners();
  }
}

/// Runs form analyses: picks frames on the device, sends them, stores the
/// rating with the video.
///
/// One at a time — each one costs money and takes most of a minute, and a
/// second would only slow the first.
class FormAnalysisRunner extends ChangeNotifier {
  final ExerciseVideoStorage storage;
  final VideoTools tools;
  final FrameSampler sampler;
  final FormAnalysisService service;
  final FormAnalysisUsage usage;
  final DateTime Function() _now;

  final Map<String, AnalysisJob> _jobs = {};

  /// This month's analyses used, counted on the device, and the cap.
  int? used;
  int get cap => FormAnalysisUsage.monthlyCap;

  FormAnalysisRunner({
    required this.storage,
    required this.tools,
    required this.service,
    FormAnalysisUsage? usage,
    FrameSampler? sampler,
    DateTime Function()? now,
  })  : sampler = sampler ?? FrameSampler(tools),
        usage = usage ?? FormAnalysisUsage(now: now),
        _now = now ?? DateTime.now;

  AnalysisJob? jobFor(String videoId) => _jobs[videoId];

  /// The analysis running now, if any.
  AnalysisJob? get running {
    for (final job in _jobs.values) {
      if (job.isRunning) return job;
    }
    return null;
  }

  bool get busy => running != null;

  /// Start analysing [video]. Returns the job, which is already running; await
  /// [AnalysisJob] changes to follow it. Returns the current job instead if
  /// [video] is already being analysed.
  AnalysisJob start(ExerciseVideo video, {String? cameraHint}) {
    final existing = _jobs[video.id];
    if (existing != null && existing.isRunning) return existing;
    final job = AnalysisJob(video.id);
    _jobs[video.id] = job;
    notifyListeners();
    _run(job, video, cameraHint);
    return job;
  }

  void cancel(String videoId) {
    final job = _jobs[videoId];
    if (job == null || !job.isRunning) return;
    job._cancel.cancel();
  }

  /// Forget a finished job, so a retry starts clean and the card stops showing
  /// an old failure.
  void dismiss(String videoId) {
    final job = _jobs[videoId];
    if (job != null && !job.isRunning) {
      _jobs.remove(videoId);
      notifyListeners();
    }
  }

  Future<void> _run(AnalysisJob job, ExerciseVideo video, String? cameraHint) async {
    final started = _now();
    try {
      // The allowance is checked before any work is done or anything is sent.
      final already = await usage.usedThisMonth();
      used = already;
      if (already >= FormAnalysisUsage.monthlyCap) {
        throw FormAnalysisException(
          FormAnalysisFailure.monthlyCap,
          'All ${FormAnalysisUsage.monthlyCap} analyses used this month.',
          used: already,
          cap: FormAnalysisUsage.monthlyCap,
        );
      }

      final file = await storage.videoFile(video);
      if (!file.existsSync()) {
        throw const FormAnalysisException(
            FormAnalysisFailure.other, 'The video file is missing.');
      }

      final info = await tools.info(file.path);
      _checkCancelled(job);
      final plan = await sampler.plan(file.path, info);
      _checkCancelled(job);
      final frames = await sampler.extract(file.path, plan);
      _checkCancelled(job);

      VideoAnalytics.analysisStarted(frameCount: frames.count);
      job._set(AnalysisPhase.uploading);

      final result = await service.analyse(
        exerciseName: video.exerciseName,
        frames: frames,
        cameraHint: cameraHint,
        cancelToken: job._cancel,
        onSendProgress: (sent) {
          if (sent >= 1) job._set(AnalysisPhase.analysing);
        },
      );
      job._set(AnalysisPhase.analysing);

      // When the frames were a guess, say so on the result rather than let it
      // read as a confident verdict.
      var analysis = result.analysis;
      if (plan.lowConfidence && plan.note != null) {
        analysis = analysis.withLimitation(plan.note!);
      }

      // Counted only now that a result exists, so a failure costs nothing.
      used = await usage.record();
      // Stored with the video, so reopening it is instant and free. If the
      // video was deleted while this ran, this is a no-op.
      await storage.setAnalysis(video.id, analysis, model: result.model, at: _now());

      job
        .._result = analysis
        .._set(AnalysisPhase.done);
      VideoAnalytics.analysisCompleted(analysis, took: _now().difference(started));
    } on FormAnalysisException catch (e) {
      _fail(job, e);
    } on VideoToolsUnavailable {
      _fail(job, const FormAnalysisException(
          FormAnalysisFailure.other, 'Video analysis is not available on this device yet.'));
    } on VideoToolsException catch (e) {
      _fail(job, FormAnalysisException(
          FormAnalysisFailure.other, 'This video could not be read (${e.code}).'));
    } catch (e) {
      _fail(job, FormAnalysisException(FormAnalysisFailure.other, '$e'));
    } finally {
      notifyListeners();
    }
  }

  void _checkCancelled(AnalysisJob job) {
    if (job.isCancelled) {
      throw const FormAnalysisException(FormAnalysisFailure.cancelled, 'Cancelled');
    }
  }

  void _fail(AnalysisJob job, FormAnalysisException e) {
    job._error = e;
    final cancelled = e.failure == FormAnalysisFailure.cancelled;
    job._set(cancelled ? AnalysisPhase.cancelled : AnalysisPhase.failed);
    if (!cancelled) VideoAnalytics.analysisFailed(e.reason);
  }
}
