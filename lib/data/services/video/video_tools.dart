import 'dart:io';
import 'package:flutter/services.dart';

/// A clip's size and length, as it is *shown* (rotation applied).
class VideoInfo {
  final int durationMs;
  final int width;
  final int height;
  final double fps;
  const VideoInfo({
    required this.durationMs,
    required this.width,
    required this.height,
    this.fps = 30,
  });

  Duration get duration => Duration(milliseconds: durationMs);
  bool get isPortrait => height >= width;
}

/// Small greyscale frames, one buffer per requested time, row by row.
class GrayFrames {
  final int width;
  final int height;
  final List<Uint8List> frames;
  const GrayFrames({required this.width, required this.height, required this.frames});
}

/// A rectangle inside the picture, each side as a fraction 0–1 of the upright
/// frame. Used to crop to the person lifting.
class NormRect {
  final double left;
  final double top;
  final double right;
  final double bottom;
  const NormRect(this.left, this.top, this.right, this.bottom);

  static const full = NormRect(0, 0, 1, 1);

  double get width => right - left;
  double get height => bottom - top;
  double get area => width * height;

  Map<String, double> toMap() =>
      {'left': left, 'top': top, 'right': right, 'bottom': bottom};

  @override
  String toString() => 'NormRect($left, $top, $right, $bottom)';
}

/// The video work the feature needs from the platform. Behind an interface so
/// the sampling maths, which is the hard part, can be tested without a phone.
abstract class VideoTools {
  Future<VideoInfo> info(String path);

  /// Free space on the device, or null if it can't be read.
  Future<int?> freeBytes();

  /// A JPEG still at [atMs].
  Future<Uint8List> thumbnail(String path, {required int atMs, int maxEdge = 480});

  /// Trim to [startMs]–[endMs] and compress to at most 720p, writing [outPath].
  /// [onProgress] gets 0–1 while it works. Throws [VideoToolsException] on
  /// failure, or [VideoExportCancelled] if [cancel] is called.
  Future<void> exportClip(
    String path,
    String outPath, {
    required int startMs,
    required int endMs,
    void Function(double progress)? onProgress,
  });

  /// Stop an [exportClip] in flight.
  Future<void> cancelExport();

  /// Greyscale frames at [timesMs], [width] pixels wide, for the motion map.
  Future<GrayFrames> grayFrames(String path, List<int> timesMs, {int width = 160});

  /// JPEG frames at [timesMs], cropped to [rect] and scaled so the long edge is
  /// at most [maxEdge]. These are the frames that get sent for analysis.
  Future<List<Uint8List>> cropFrames(
    String path,
    List<int> timesMs, {
    NormRect rect = NormRect.full,
    int maxEdge = 768,
    double quality = 0.7,
  });
}

class VideoToolsException implements Exception {
  final String code;
  final String message;
  const VideoToolsException(this.code, this.message);

  @override
  String toString() => 'VideoToolsException($code): $message';
}

class VideoExportCancelled extends VideoToolsException {
  const VideoExportCancelled() : super('cancelled', 'Export cancelled');
}

/// This platform has no implementation yet (Android: iOS comes first, see
/// doc/video_analysis_plan.md, section 5). The feature is hidden there.
class VideoToolsUnavailable extends VideoToolsException {
  const VideoToolsUnavailable() : super('unavailable', 'Video tools are not available here');
}

/// Whether this build can run the video feature at all.
bool get videoToolsSupported => Platform.isIOS;

/// Talks to `ios/Runner/VideoToolsChannel.swift`.
class MethodChannelVideoTools implements VideoTools {
  static const _channel = MethodChannel('befit/video_tools');

  String? _exportToken;

  Future<T> _call<T>(String method, Map<String, Object?> args) async {
    try {
      final result = await _channel.invokeMethod<T>(method, args);
      if (result == null && null is! T) {
        throw VideoToolsException('empty', '$method returned nothing');
      }
      return result as T;
    } on MissingPluginException {
      throw const VideoToolsUnavailable();
    } on PlatformException catch (e) {
      if (e.code == 'cancelled') throw const VideoExportCancelled();
      throw VideoToolsException(e.code, e.message ?? 'Video operation failed');
    }
  }

  @override
  Future<int?> freeBytes() async {
    try {
      return await _call<int?>('freeSpace', const {});
    } on VideoToolsException {
      return null;
    }
  }

  @override
  Future<VideoInfo> info(String path) async {
    final m = await _call<Map<Object?, Object?>>('info', {'path': path});
    return VideoInfo(
      durationMs: (m['durationMs'] as num).toInt(),
      width: (m['width'] as num).toInt(),
      height: (m['height'] as num).toInt(),
      fps: (m['fps'] as num?)?.toDouble() ?? 30,
    );
  }

  @override
  Future<Uint8List> thumbnail(String path, {required int atMs, int maxEdge = 480}) =>
      _call<Uint8List>('thumbnail', {'path': path, 'atMs': atMs, 'maxEdge': maxEdge});

  @override
  Future<void> exportClip(
    String path,
    String outPath, {
    required int startMs,
    required int endMs,
    void Function(double progress)? onProgress,
  }) async {
    final token = DateTime.now().microsecondsSinceEpoch.toString();
    _exportToken = token;
    var running = true;

    // The platform call only answers when the export ends, so progress is polled.
    Future<void> poll() async {
      while (running) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!running) return;
        try {
          final p = await _call<double>('exportProgress', {'token': token});
          if (running) onProgress?.call(p.clamp(0.0, 1.0));
        } catch (_) {
          return;
        }
      }
    }

    if (onProgress != null) poll();
    try {
      await _call<bool>('exportClip', {
        'path': path,
        'outPath': outPath,
        'token': token,
        'startMs': startMs,
        'endMs': endMs,
      });
      onProgress?.call(1);
    } finally {
      running = false;
      if (_exportToken == token) _exportToken = null;
    }
  }

  @override
  Future<void> cancelExport() async {
    final token = _exportToken;
    if (token == null) return;
    await _call<Object?>('cancelExport', {'token': token});
  }

  @override
  Future<GrayFrames> grayFrames(String path, List<int> timesMs, {int width = 160}) async {
    final m = await _call<Map<Object?, Object?>>(
        'grayFrames', {'path': path, 'timesMs': timesMs, 'width': width});
    return GrayFrames(
      width: (m['width'] as num).toInt(),
      height: (m['height'] as num).toInt(),
      frames: [for (final f in (m['frames'] as List)) f as Uint8List],
    );
  }

  @override
  Future<List<Uint8List>> cropFrames(
    String path,
    List<int> timesMs, {
    NormRect rect = NormRect.full,
    int maxEdge = 768,
    double quality = 0.7,
  }) async {
    final list = await _call<List<Object?>>('cropFrames', {
      'path': path,
      'timesMs': timesMs,
      'rect': rect.toMap(),
      'maxEdge': maxEdge,
      'quality': quality,
    });
    return [for (final f in list) f as Uint8List];
  }
}
