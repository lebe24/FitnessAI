import 'package:fitness/data/services/analytics/video_analytics.dart';
import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/data/services/video/form_analysis_runner.dart';
import 'package:fitness/data/services/video/form_analysis_service.dart';
import 'package:fitness/data/services/video/video_import_service.dart';
import 'package:fitness/data/services/video/video_notice_storage.dart';
import 'package:fitness/data/services/video/video_tools.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:fitness/ui/features/video/views/form_analysis_sheet.dart';
import 'package:fitness/ui/features/video/views/video_player_page.dart';
import 'package:fitness/ui/features/video/views/video_sheets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void videoSnack(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
      backgroundColor: error ? Colors.redAccent : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
}

/// What to tell the user about a failed analysis.
String analysisFailureMessage(FormAnalysisException e) => switch (e.failure) {
      FormAnalysisFailure.offline => "You're offline. Check your connection and try again.",
      FormAnalysisFailure.timeout => 'That took too long. Give it another go in a moment.',
      FormAnalysisFailure.monthlyCap => e.cap != null
          ? "You've used all ${e.cap} form analyses for this month. They reset on the 1st."
          : "You've used all of this month's form analyses. They reset on the 1st.",
      FormAnalysisFailure.rateLimited => 'Too many analyses at once. Try again in a minute.',
      FormAnalysisFailure.couldNotAnalyse =>
        "Couldn't analyse this clip. It wasn't counted, so you can try again.",
      FormAnalysisFailure.signedOut => 'Please sign in again to analyse a video.',
      FormAnalysisFailure.badRequest => "This clip couldn't be sent. Try recording it again.",
      FormAnalysisFailure.unavailable =>
        'Form analysis isn\'t switched on yet. Please try again after the next update.',
      FormAnalysisFailure.cancelled => 'Analysis cancelled.',
      FormAnalysisFailure.other => 'Something went wrong. Please try again.',
    };

// ── Add ───────────────────────────────────────────────────────────────────────

/// Record or pick a clip, trim it if it is over a minute, compress and save it
/// against [exerciseName]. Returns the saved video, or null if nothing was saved.
Future<ExerciseVideo?> addVideoFlow(
  BuildContext context, {
  required String exerciseName,
  required List<String> muscles,
  DateTime? workoutDate,
  String? dayLabel,
  VideoImportService? importer,
  VideoTools? tools,
}) async {
  final import = importer ?? sl<VideoImportService>();
  final videoTools = tools ?? import.tools;

  final source = await showAddVideoSheet(context);
  if (source == null || !context.mounted) return null;

  if (source == VideoSource.record && !await VideoNoticeStorage.tipsSeen()) {
    if (!context.mounted) return null;
    if (!await showRecordingTips(context, forRecording: true)) return null;
    if (!context.mounted) return null;
  }

  final PickedVideo? picked;
  try {
    picked = await import.pick(source);
  } on VideoImportException catch (e) {
    if (context.mounted) videoSnack(context, e.message, error: true);
    return null;
  }
  if (picked == null || !context.mounted) return null;

  var start = 0;
  if (picked.needsTrim) {
    final chosen = await showTrimSheet(context, picked, videoTools);
    if (chosen == null || !context.mounted) return null;
    start = chosen;
  }

  try {
    final saved = await showSavingDialog<ExerciseVideo>(
      context,
      run: (onProgress) => import.save(
        picked!,
        exerciseName: exerciseName,
        muscles: muscles,
        startMs: start,
        workoutDate: workoutDate,
        dayLabel: dayLabel,
        onProgress: onProgress,
      ),
      onCancel: import.cancel,
    );
    if (saved != null) {
      VideoAnalytics.added(
        source: source == VideoSource.record ? 'record' : 'library',
        duration: saved.duration,
      );
      if (context.mounted) videoSnack(context, 'Video saved');
    }
    return saved;
  } on VideoImportException catch (e) {
    if (e.problem != VideoImportProblem.cancelled && context.mounted) {
      videoSnack(context, e.message, error: true);
    }
    return null;
  }
}

// ── Analyse ───────────────────────────────────────────────────────────────────

/// Start analysing [video]: the paywall first (saving and playing stay free),
/// then the one-time privacy notice, then the run. Opens the result sheet when
/// it finishes, if the screen is still there.
Future<void> analyseFlow(
  BuildContext context,
  ExerciseVideo video, {
  FormAnalysisRunner? runner,
  ExerciseVideoStorage? storage,
}) async {
  await requirePremium(context, PremiumFeature.formAnalysis, () async {
    if (!context.mounted) return;
    final r = runner ?? sl<FormAnalysisRunner>();
    final store = storage ?? sl<ExerciseVideoStorage>();

    final running = r.running;
    if (running != null && running.videoId != video.id) {
      videoSnack(context, 'Another video is being analysed. Wait for it to finish first.',
          error: true);
      return;
    }
    if (!await ensureAnalysisNotice(context)) return;
    if (!context.mounted) return;

    r.dismiss(video.id);
    final job = r.start(video);

    void onChange() {
      if (job.isRunning) return;
      job.removeListener(onChange);
      if (job.phase == AnalysisPhase.done && context.mounted) {
        openAnalysis(context, video.id, storage: store, runner: r);
      } else if (job.phase == AnalysisPhase.failed && job.error != null && context.mounted) {
        videoSnack(context, analysisFailureMessage(job.error!), error: true);
      }
    }

    job.addListener(onChange);
  });
}

/// Show a video's stored result.
Future<void> openAnalysis(
  BuildContext context,
  String videoId, {
  ExerciseVideoStorage? storage,
  FormAnalysisRunner? runner,
}) async {
  final store = storage ?? sl<ExerciseVideoStorage>();
  final video = await store.byId(videoId);
  final analysis = video?.analysis;
  if (video == null || analysis == null || !context.mounted) return;
  await showFormAnalysisSheet(
    context,
    video: video,
    analysis: analysis,
    onRerun: () => analyseFlow(context, video, runner: runner, storage: store),
  );
}

// ── Play / delete ─────────────────────────────────────────────────────────────

Future<void> openVideo(BuildContext context, ExerciseVideo video) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => VideoPlayerPage(videoId: video.id)),
  );
}

/// Confirm, then delete the video, its thumbnail and its stored result.
Future<bool> confirmDeleteVideo(
  BuildContext context,
  ExerciseVideo video, {
  ExerciseVideoStorage? storage,
  FormAnalysisRunner? runner,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF0D0F14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Delete this video?',
          style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
      content: Text(
        video.isAnalysed
            ? 'The video and its form rating will be removed from this phone. This can’t be undone.'
            : 'The video will be removed from this phone. This can’t be undone.',
        style: GoogleFonts.inter(fontSize: 13.5, height: 1.45, color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Keep', style: GoogleFonts.inter(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent)),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  // Stop an analysis in flight first, so it doesn't write into a deleted video.
  (runner ?? sl<FormAnalysisRunner>()).cancel(video.id);
  await (storage ?? sl<ExerciseVideoStorage>()).delete(video.id);
  VideoAnalytics.deleted(analysed: video.isAnalysed);
  return true;
}
