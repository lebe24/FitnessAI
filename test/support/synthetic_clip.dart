import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fitness/data/services/video/frame_sampler.dart';
import 'package:fitness/data/services/video/video_tools.dart';

const kClipW = 40, kClipH = 30, kClipStep = 125;

/// A synthetic clip: a 12×10 "lifter" (a tenth of the frame, like a person filmed from a few metres) that stands still except during bursts,
/// when it shifts 3 px a frame. A faint noise floor sits under everything.
class SyntheticClip {
  final int durationMs;
  final List<(int, int)> bursts; // ms ranges
  final bool bystander;

  /// For continuous sets: motion strength follows a sine of this period.
  final int? periodMs;

  /// Stretches where the camera itself moves: every pixel changes.
  final List<(int, int)> cameraMoves;

  SyntheticClip(
    this.durationMs, {
    this.bursts = const [],
    this.bystander = false,
    this.periodMs,
    this.cameraMoves = const [],
  });

  List<int> get times => FrameSampler.mapTimes(durationMs, kClipStep);

  GrayFrames frames() {
    final rnd = math.Random(4);
    final out = <Uint8List>[];
    var shift = 0;
    for (final t in times) {
      var moving = bursts.any((b) => t >= b.$1 && t <= b.$2);
      if (periodMs != null) {
        moving = math.sin(2 * math.pi * t / periodMs!) > 0.2;
      }
      if (moving) shift += 3;
      final f = Uint8List(kClipW * kClipH);
      final camera = cameraMoves.any((c) => t >= c.$1 && t <= c.$2);
      for (var i = 0; i < f.length; i++) {
        // A faint noise floor; a camera move replaces the whole picture.
        f[i] = camera ? rnd.nextInt(256) : 100 + rnd.nextInt(3) - 1;
      }
      // Textured, like cloth: moving it changes every pixel, not only its edges.
      void block(int x0, int y0, int bw, int bh, int v) {
        for (var y = y0; y < math.min(kClipH, y0 + bh); y++) {
          for (var x = x0; x < math.min(kClipW, x0 + bw); x++) {
            f[y * kClipW + x] = v + ((x - x0) * 13 + (y - y0) * 29) % 110;
          }
        }
      }

      // The lifter, bouncing between two columns while it is moving.
      final dx = 6 + (shift % 6);
      block(dx, 10, 12, 10, 100);
      if (bystander) {
        // Far corner, wiggling a little all through the clip.
        block(30 + (t ~/ kClipStep) % 2, 20, 6, 8, 160);
      }
      out.add(f);
    }
    return GrayFrames(width: kClipW, height: kClipH, frames: out);
  }
}


/// A [VideoTools] that serves a [SyntheticClip] and records what was asked.
class FakeVideoTools implements VideoTools {
  final SyntheticClip? clip;
  final VideoInfo infoResult;
  int? free;

  /// Throw this from the next call to each method, if set.
  Object? exportError;
  Object? infoError;
  Object? thumbnailError;

  int grayCalls = 0, cropCalls = 0, exportCalls = 0, cancelCalls = 0;
  List<int> lastCropTimes = const [];
  NormRect? lastRect;
  ({int start, int end})? lastExport;

  /// Called while an export "runs", so tests can cancel mid-way.
  Future<void> Function()? duringExport;

  FakeVideoTools({
    this.clip,
    this.infoResult = const VideoInfo(durationMs: 20000, width: 720, height: 1280),
    this.free = 5 * 1024 * 1024 * 1024,
  });

  @override
  Future<int?> freeBytes() async => free;

  @override
  Future<VideoInfo> info(String path) async {
    if (infoError != null) throw infoError!;
    return infoResult;
  }

  @override
  Future<Uint8List> thumbnail(String path, {required int atMs, int maxEdge = 480}) async {
    if (thumbnailError != null) throw thumbnailError!;
    return Uint8List.fromList([0xff, 0xd8, 0xff, 9]);
  }

  @override
  Future<void> exportClip(
    String path,
    String outPath, {
    required int startMs,
    required int endMs,
    void Function(double progress)? onProgress,
  }) async {
    exportCalls++;
    lastExport = (start: startMs, end: endMs);
    onProgress?.call(0.5);
    await duringExport?.call();
    if (exportError != null) throw exportError!;
    await File(outPath).writeAsBytes(List.filled(2048, 1));
    onProgress?.call(1);
  }

  @override
  Future<void> cancelExport() async => cancelCalls++;

  @override
  Future<GrayFrames> grayFrames(String path, List<int> timesMs, {int width = 160}) async {
    grayCalls++;
    final c = clip;
    if (c == null) throw const VideoToolsException('no_clip', 'no synthetic clip');
    return c.frames();
  }

  @override
  Future<List<Uint8List>> cropFrames(
    String path,
    List<int> timesMs, {
    NormRect rect = NormRect.full,
    int maxEdge = 768,
    double quality = 0.7,
  }) async {
    cropCalls++;
    lastCropTimes = timesMs;
    lastRect = rect;
    return [for (final _ in timesMs) Uint8List.fromList([0xff, 0xd8, 0xff, 1, 2, 3])];
  }
}
