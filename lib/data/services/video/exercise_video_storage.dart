import 'dart:io';

import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// What [ExerciseVideoStorage.cleanUp] removed.
class CleanupReport {
  final int orphanFiles;
  final int brokenEntries;
  const CleanupReport({this.orphanFiles = 0, this.brokenEntries = 0});
  bool get isEmpty => orphanFiles == 0 && brokenEntries == 0;
}

/// The user's workout videos, kept on the device.
///
/// Files go in `exercise_videos/` under the app documents folder (`<id>.mp4`
/// and `<id>.jpg`); the index is a Hive box, the same arrangement as
/// `BodyScanStorage`. Videos never leave the device: only still frames are sent
/// for analysis (doc/video_analysis_plan.md, D1).
///
/// A [ChangeNotifier] so the exercise page and the muscle page, which show the
/// same videos, stay in step when one of them adds or deletes.
class ExerciseVideoStorage extends ChangeNotifier {
  static const boxName = 'exercise_videos';
  static const folderName = 'exercise_videos';

  final Future<Directory> Function() _documents;
  Box<Map>? _box;
  Directory? _root;

  ExerciseVideoStorage({Future<Directory> Function()? documents})
      : _documents = documents ?? getApplicationDocumentsDirectory;

  /// Opens the box. Called at startup, before anything reads.
  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) await Hive.openBox<Map>(boxName);
  }

  Future<Box<Map>> _open() async {
    final existing = _box;
    if (existing != null && existing.isOpen) return existing;
    return _box = Hive.isBoxOpen(boxName)
        ? Hive.box<Map>(boxName)
        : await Hive.openBox<Map>(boxName);
  }

  Future<Directory> _folder() async {
    final cached = _root;
    if (cached != null) return cached;
    final docs = await _documents();
    final dir = Directory(p.join(docs.path, folderName));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return _root = dir;
  }

  /// Where a video's files go, as paths relative to the documents folder.
  static String videoPathFor(String id) => p.join(folderName, '$id.mp4');
  static String thumbnailPathFor(String id) => p.join(folderName, '$id.jpg');

  Future<File> videoFile(ExerciseVideo v) async =>
      File(p.join((await _documents()).path, v.filePath));

  Future<File> thumbnailFile(ExerciseVideo v) async =>
      File(p.join((await _documents()).path, v.thumbnailPath));

  // ── Reading ───────────────────────────────────────────────────────────────────

  /// Every video, newest first. A damaged entry is skipped, not fatal.
  Future<List<ExerciseVideo>> all() async {
    final box = await _open();
    final out = <ExerciseVideo>[];
    for (final raw in box.values) {
      final v = ExerciseVideo.tryFromMap(raw);
      if (v != null) out.add(v);
    }
    out.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return out;
  }

  Future<ExerciseVideo?> byId(String id) async {
    final raw = (await _open()).get(id);
    return raw == null ? null : ExerciseVideo.tryFromMap(raw);
  }

  /// Videos for one exercise, newest first, matching name variants.
  Future<List<ExerciseVideo>> forExercise(String name) async {
    final key = ExerciseHistory.keyFor(name);
    if (key.isEmpty) return const [];
    return [
      for (final v in await all())
        if (v.exerciseKey == key) v,
    ];
  }

  /// Videos that train [slug], newest first. Uses the muscles saved with each
  /// video, never recomputed.
  Future<List<ExerciseVideo>> forMuscle(String slug) async => [
        for (final v in await all())
          if (v.muscles.contains(slug)) v,
      ];

  /// Videos per muscle slug, for the badge on the Muscles trained card.
  Future<Map<String, int>> countsByMuscle() async {
    final counts = <String, int>{};
    for (final v in await all()) {
      for (final m in v.muscles) {
        counts[m] = (counts[m] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<int> totalBytes() async {
    var total = 0;
    for (final v in await all()) {
      total += v.sizeBytes;
    }
    return total;
  }

  // ── Writing ───────────────────────────────────────────────────────────────────

  /// Move a finished clip and its thumbnail into place and record it.
  ///
  /// [video] and [thumbnail] are temporary files from the import step; they are
  /// moved, not copied, so a 40 MB clip is not held twice.
  Future<ExerciseVideo> save({
    required String id,
    required File video,
    required File thumbnail,
    required int durationMs,
    required String exerciseName,
    required List<String> muscles,
    DateTime? recordedAt,
    DateTime? workoutDate,
    String? dayLabel,
  }) async {
    final box = await _open();
    final docs = (await _documents()).path;
    await _folder();

    final videoRel = videoPathFor(id);
    final thumbRel = thumbnailPathFor(id);
    final size = await _moveInto(video, p.join(docs, videoRel));
    await _moveInto(thumbnail, p.join(docs, thumbRel));

    final saved = ExerciseVideo(
      id: id,
      recordedAt: recordedAt ?? DateTime.now(),
      durationMs: durationMs,
      sizeBytes: size,
      exerciseName: exerciseName,
      exerciseKey: ExerciseHistory.keyFor(exerciseName),
      muscles: List.unmodifiable(muscles),
      workoutDate: workoutDate,
      dayLabel: dayLabel,
      filePath: videoRel,
      thumbnailPath: thumbRel,
    );
    await box.put(id, saved.toMap());
    notifyListeners();
    return saved;
  }

  /// Rename when possible; copy and delete across volumes. Returns the size.
  Future<int> _moveInto(File source, String destination) async {
    final target = File(destination);
    if (target.existsSync()) await target.delete();
    try {
      await source.rename(destination);
    } on FileSystemException {
      await source.copy(destination);
      await source.delete();
    }
    return target.length();
  }

  /// Keep a result with its video. A no-op if the video was deleted meanwhile,
  /// which is what happens when the user deletes it while it is analysing.
  Future<ExerciseVideo?> setAnalysis(
    String id,
    FormAnalysis analysis, {
    String? model,
    DateTime? at,
  }) async {
    final box = await _open();
    final current = await byId(id);
    if (current == null) return null;
    final updated = current.withAnalysis(analysis, at: at ?? DateTime.now(), model: model);
    await box.put(id, updated.toMap());
    notifyListeners();
    return updated;
  }

  /// The entry, the file and the thumbnail go together.
  Future<void> delete(String id) async {
    final box = await _open();
    final v = await byId(id);
    await box.delete(id);
    if (v != null) {
      await _deleteQuietly(await videoFile(v));
      await _deleteQuietly(await thumbnailFile(v));
    } else {
      final docs = (await _documents()).path;
      await _deleteQuietly(File(p.join(docs, videoPathFor(id))));
      await _deleteQuietly(File(p.join(docs, thumbnailPathFor(id))));
    }
    notifyListeners();
  }

  /// Delete every video, thumbnail and entry (Profile → delete all my videos).
  Future<void> deleteAll() async {
    final box = await _open();
    await box.clear();
    final dir = await _folder();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
    notifyListeners();
  }

  Future<void> _deleteQuietly(File f) async {
    try {
      if (f.existsSync()) await f.delete();
    } on FileSystemException {
      // A file that can't be removed now is picked up by [cleanUp] next launch.
    }
  }

  /// Startup repair. Removes files with no index entry (a crash between moving
  /// the file and writing the entry) and entries whose video file is gone (the
  /// user, or iOS, cleared it). Entries missing only a thumbnail are kept: the
  /// video still plays.
  Future<CleanupReport> cleanUp() async {
    final box = await _open();
    final dir = await _folder();
    final docs = (await _documents()).path;

    var broken = 0;
    final known = <String>{};
    for (final key in box.keys.toList()) {
      final v = ExerciseVideo.tryFromMap(box.get(key) ?? const {});
      if (v == null || !File(p.join(docs, v.filePath)).existsSync()) {
        await box.delete(key);
        if (v != null) await _deleteQuietly(File(p.join(docs, v.thumbnailPath)));
        broken++;
        continue;
      }
      known
        ..add(p.basename(v.filePath))
        ..add(p.basename(v.thumbnailPath));
    }

    var orphans = 0;
    for (final entity in dir.listSync()) {
      if (entity is File && !known.contains(p.basename(entity.path))) {
        await _deleteQuietly(entity);
        orphans++;
      }
    }

    final report = CleanupReport(orphanFiles: orphans, brokenEntries: broken);
    if (!report.isEmpty) notifyListeners();
    return report;
  }
}
