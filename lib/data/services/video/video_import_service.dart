import 'dart:io';
import 'dart:math' as math;

import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/data/services/video/video_tools.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum VideoSource { record, library }

enum VideoImportProblem {
  /// Camera or photo library access was refused.
  permission,

  /// Not enough free space to store a clip.
  lowStorage,

  /// The file has no video in it, or can't be read.
  unreadable,

  /// Compressing or trimming failed.
  failed,

  /// The user stopped it.
  cancelled,

  /// This device can't do it (not iOS yet).
  unsupported,
}

class VideoImportException implements Exception {
  final VideoImportProblem problem;
  final String message;
  const VideoImportException(this.problem, this.message);

  @override
  String toString() => 'VideoImportException(${problem.name}): $message';
}

/// A clip the user chose, not yet saved.
class PickedVideo {
  final String path;
  final VideoInfo info;
  final VideoSource source;
  const PickedVideo(this.path, this.info, this.source);

  /// Longer than can be saved whole, so the user chooses which part to keep.
  bool get needsTrim => info.durationMs > VideoImportService.maxClipMs;
}

/// Asks the user for a clip. Behind an interface so tests don't open a camera.
abstract class VideoPicker {
  /// The chosen file's path, or null if the user backed out.
  Future<String?> pick(VideoSource source);
}

class ImagePickerVideoPicker implements VideoPicker {
  final ImagePicker _picker;
  ImagePickerVideoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  @override
  Future<String?> pick(VideoSource source) async {
    try {
      final file = await _picker.pickVideo(
        source: source == VideoSource.record ? ImageSource.camera : ImageSource.gallery,
        // The camera stops at the cap; the library has no such option, which is
        // what the trim step is for.
        maxDuration: const Duration(seconds: 60),
      );
      return file?.path;
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied' ||
          e.code == 'photo_access_denied' ||
          e.code == 'camera_access_restricted' ||
          e.code == 'photo_access_restricted') {
        throw const VideoImportException(
          VideoImportProblem.permission,
          'BeFit needs access to do that. You can allow it in Settings.',
        );
      }
      rethrow;
    }
  }
}

/// Turns a recorded or chosen video into a small saved clip with a thumbnail.
///
/// Steps (doc/video_analysis_plan.md, step 3): check there is room, trim to 60
/// seconds if it is longer, compress to at most 720p, make a thumbnail, then
/// hand both files to [ExerciseVideoStorage].
class VideoImportService {
  static const maxClipMs = 60 * 1000;

  /// Refuse to start with less free space than this: a clip is up to about
  /// 40 MB, and the phone needs room to work.
  static const minFreeBytes = 300 * 1024 * 1024;

  final VideoTools tools;
  final ExerciseVideoStorage storage;
  final VideoPicker picker;
  final Future<Directory> Function() _temp;
  final String Function() _newId;
  final bool Function() _supported;

  VideoImportService({
    required this.tools,
    required this.storage,
    VideoPicker? picker,
    Future<Directory> Function()? tempDirectory,
    String Function()? newId,
    bool Function()? supported,
  })  : picker = picker ?? ImagePickerVideoPicker(),
        _supported = supported ?? (() => videoToolsSupported),
        _temp = tempDirectory ?? getTemporaryDirectory,
        _newId = newId ?? (() => const Uuid().v4());

  /// Ask for a clip and read how long it is. Null if the user backed out.
  Future<PickedVideo?> pick(VideoSource source) async {
    if (!_supported()) {
      throw const VideoImportException(
          VideoImportProblem.unsupported, 'Workout videos are not available on this device yet.');
    }
    final free = await tools.freeBytes();
    if (free != null && free < minFreeBytes) {
      throw const VideoImportException(
        VideoImportProblem.lowStorage,
        'Your phone is almost full. Free up some space, then try again.',
      );
    }

    final path = await picker.pick(source);
    if (path == null) return null;
    try {
      final info = await tools.info(path);
      if (info.durationMs <= 0) throw const VideoToolsException('no_video', 'empty');
      return PickedVideo(path, info, source);
    } on VideoToolsUnavailable {
      throw const VideoImportException(
          VideoImportProblem.unsupported, 'Workout videos are not available on this device yet.');
    } on VideoToolsException {
      throw const VideoImportException(
          VideoImportProblem.unreadable, "That video can't be read. Try another one.");
    }
  }

  /// The window kept from [picked]: [startMs] up to 60 seconds on, never past
  /// the end.
  static (int, int) windowFor(PickedVideo picked, int startMs) {
    final total = picked.info.durationMs;
    final start = startMs.clamp(0, math.max(0, total - 1000)).toInt();
    return (start, math.min(total, start + maxClipMs));
  }

  /// Trim, compress and save. [startMs] is where the kept part begins (only
  /// meaningful when [PickedVideo.needsTrim]).
  Future<ExerciseVideo> save(
    PickedVideo picked, {
    required String exerciseName,
    required List<String> muscles,
    int startMs = 0,
    DateTime? workoutDate,
    String? dayLabel,
    void Function(double progress)? onProgress,
  }) async {
    final (start, end) = windowFor(picked, picked.needsTrim ? startMs : 0);
    final id = _newId();
    final tmp = await _temp();
    final outVideo = File(p.join(tmp.path, 'befit_$id.mp4'));
    final outThumb = File(p.join(tmp.path, 'befit_$id.jpg'));

    try {
      try {
        await tools.exportClip(
          picked.path,
          outVideo.path,
          startMs: start,
          endMs: end,
          onProgress: onProgress,
        );
      } on VideoExportCancelled {
        throw const VideoImportException(VideoImportProblem.cancelled, 'Cancelled');
      } on VideoToolsException catch (e) {
        throw VideoImportException(VideoImportProblem.failed,
            "This video couldn't be prepared (${e.code}). Try another one.");
      }

      final duration = end - start;
      try {
        final thumb = await tools.thumbnail(outVideo.path,
            atMs: math.min(1000, duration ~/ 2), maxEdge: 480);
        await outThumb.writeAsBytes(thumb, flush: true);
      } on VideoToolsException {
        // A clip without a picture is still a clip: write an empty placeholder
        // so storage has a file to move, and the card shows its icon instead.
        await outThumb.writeAsBytes(const [], flush: true);
      }

      final saved = await storage.save(
        id: id,
        video: outVideo,
        thumbnail: outThumb,
        durationMs: duration,
        exerciseName: exerciseName,
        muscles: muscles,
        workoutDate: workoutDate,
        dayLabel: dayLabel,
      );
      await _discardSource(picked);
      return saved;
    } finally {
      for (final f in [outVideo, outThumb]) {
        try {
          if (f.existsSync()) await f.delete();
        } on FileSystemException {
          // It is in the temporary folder; the system clears that itself.
        }
      }
    }
  }

  Future<void> cancel() => tools.cancelExport();

  /// The picker leaves its own copy in the temporary folder (the library copy
  /// can be hundreds of MB). Remove it once the clip is saved.
  Future<void> _discardSource(PickedVideo picked) async {
    try {
      final tmp = (await _temp()).path;
      final src = File(picked.path);
      if (src.existsSync() && p.isWithin(tmp, src.path)) await src.delete();
    } on FileSystemException {
      // Best effort.
    }
  }
}
