import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class ProgressPhoto {
  final String id;
  /// Absolute path, resolved against the *current* session's documents
  /// directory. Never persist this directly — persist [relativePath].
  final String localPath;
  /// Path relative to the app documents directory, e.g. "progress_photos/123.jpg".
  /// This is what's actually stored, since the documents dir's absolute
  /// prefix (container UUID on iOS) can change between app sessions.
  final String relativePath;
  final DateTime takenAt;
  final String? note;

  ProgressPhoto({
    required this.id,
    required this.localPath,
    required this.relativePath,
    required this.takenAt,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'relativePath': relativePath,
        'takenAt': takenAt.toIso8601String(),
        'note': note,
      };

  static ProgressPhoto fromMap(Map<dynamic, dynamic> m, String docsPath) {
    // Backward-compat: older entries stored an absolute 'localPath' instead
    // of 'relativePath'. Derive the relative path from it so future reads
    // resolve correctly even after the documents dir prefix changes again.
    final rel = (m['relativePath'] as String?) ??
        _relativeFromLegacyAbsolute(m['localPath'] as String?);
    return ProgressPhoto(
      id: m['id'] as String,
      relativePath: rel,
      localPath: '$docsPath/$rel',
      takenAt: DateTime.parse(m['takenAt'] as String),
      note: m['note'] as String?,
    );
  }

  static String _relativeFromLegacyAbsolute(String? absolute) {
    if (absolute == null) return 'progress_photos/unknown.jpg';
    final marker = 'progress_photos/';
    final idx = absolute.indexOf(marker);
    if (idx == -1) return 'progress_photos/unknown.jpg';
    return absolute.substring(idx);
  }
}

class ProgressPhotoService {
  static const _boxName = 'progress_photos';
  static Box<Map>? _box;

  static Future<Box<Map>> get _boxInstance async {
    _box ??= await Hive.openBox<Map>(_boxName);
    return _box!;
  }

  Future<String> get _docsPath async =>
      (await getApplicationDocumentsDirectory()).path;

  /// Copy the picked file into app documents so it persists after cache
  /// clears. Returns the path relative to the documents directory.
  Future<String> saveImageFile(File source) async {
    final docsPath = await _docsPath;
    final dest = Directory('$docsPath/progress_photos');
    await dest.create(recursive: true);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final ext = source.path.split('.').last;
    final target = File('${dest.path}/$id.$ext');
    await source.copy(target.path);
    return 'progress_photos/$id.$ext';
  }

  Future<void> addPhoto({
    required String id,
    required String relativePath,
    required DateTime takenAt,
    String? note,
  }) async {
    final box = await _boxInstance;
    await box.put(id, {
      'id': id,
      'relativePath': relativePath,
      'takenAt': takenAt.toIso8601String(),
      'note': note,
    });
  }

  Future<List<ProgressPhoto>> getAllPhotos() async {
    final box = await _boxInstance;
    final docsPath = await _docsPath;
    return box.values
        .map((m) => ProgressPhoto.fromMap(m, docsPath))
        .toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
  }

  Future<void> deletePhoto(ProgressPhoto photo) async {
    final box = await _boxInstance;
    await box.delete(photo.id);
    // Best-effort file deletion
    try { await File(photo.localPath).delete(); } catch (_) {}
  }

  Future<void> updateNote(String id, String note) async {
    final box = await _boxInstance;
    final raw = box.get(id);
    if (raw != null) {
      final updated = Map<String, dynamic>.from(raw)..['note'] = note;
      await box.put(id, updated);
    }
  }
}
