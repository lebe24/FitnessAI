import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resolves a possibly-stale absolute file path to one valid in the
/// *current* app session.
///
/// On iOS, the app sandbox container UUID (and therefore the absolute
/// prefix of getApplicationDocumentsDirectory()) can change between
/// sessions even though the relative folder layout underneath it survives.
/// Paths persisted with the old absolute prefix silently stop resolving —
/// this rebuilds them against the current documents directory using the
/// known subfolder name as an anchor.
class ImagePathResolver {
  static const knownSubfolders = ['fitness_images', 'progress_photos'];

  /// Returns an absolute path that exists on disk right now, or null if the
  /// file genuinely cannot be found under any known subfolder.
  static Future<String?> resolve(String? storedPath) async {
    if (storedPath == null || storedPath.isEmpty) return null;

    // Fast path: the stored path is already valid for this session.
    if (await File(storedPath).exists()) return storedPath;

    final docsDir = await getApplicationDocumentsDirectory();
    for (final dir in knownSubfolders) {
      final marker = '$dir/';
      final idx = storedPath.indexOf(marker);
      if (idx == -1) continue;
      final rebuilt = '${docsDir.path}/${storedPath.substring(idx)}';
      if (await File(rebuilt).exists()) return rebuilt;
    }
    return null;
  }
}
