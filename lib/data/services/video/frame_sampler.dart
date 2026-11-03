import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fitness/data/services/video/video_tools.dart';

/// Knobs for [FrameSampler]. The defaults come from the test clip in
/// doc/video_analysis_plan.md, section 2: a pull that lasts about half a second
/// inside a two-and-a-half-minute clip.
class SamplerConfig {
  /// How often the clip is looked at to build the motion map.
  final int stepMs;
  final int grayWidth;

  /// Frames sent for analysis, including the set-up frame.
  final int frameBudget;

  /// Motion has to clear this fraction of the way from the clip's resting level
  /// to its strongest moments to count as activity.
  final double activeFraction;

  /// Whatever the clip, motion below this (as a fraction of full brightness
  /// change) is noise, so a still clip is not read as active. Hand-held gym
  /// footage flickers by about 0.012 on the benchmark clip.
  final double noiseFloor;

  /// A frame where more than this share of the picture changed noticeably is the
  /// camera moving (picking the phone up, panning), not a person lifting: on the
  /// benchmark clip the lifts changed at most 7% of the frame and the camera
  /// move 13–68%. Such frames, and the ones next to them, are not activity, and
  /// they are left out when judging how strong the lifting is.
  final double cameraMoveFraction;

  /// The most that is looked at: the busiest stretch this long. A set of reps
  /// fits well inside it, and it drops activity at the start and end of a clip
  /// (starting the recording, walking to stop it) and anyone else's movement far
  /// from the set.
  final int focusWindowMs;

  /// Bursts closer together than this are one movement (down and up phases).
  final int mergeGapMs;

  /// Shorter bursts are camera shake or someone walking through.
  final int minSegmentMs;

  /// Context kept either side of an active stretch.
  final int paddingMs;

  /// At most this much active motion is analysed; the strongest is kept.
  final int maxActiveMs;

  /// Peaks closer than this are the same rep.
  final int minRepGapMs;

  /// A stretch longer than this is searched for several reps.
  final int splitAboveMs;

  /// Fallback when nothing moves clearly.
  final int fallbackFrames;

  const SamplerConfig({
    this.stepMs = 125,
    this.grayWidth = 120,
    this.frameBudget = 12,
    this.activeFraction = 0.25,
    this.noiseFloor = 0.014,
    this.cameraMoveFraction = 0.15,
    this.focusWindowMs = 40000,
    this.mergeGapMs = 600,
    this.minSegmentMs = 250,
    this.paddingMs = 250,
    this.maxActiveMs = 30000,
    this.minRepGapMs = 1000,
    this.splitAboveMs = 2500,
    this.fallbackFrames = 8,
  });
}

/// One stretch of the clip with movement in it.
class Segment {
  final int startMs;
  final int endMs;
  final double energy;
  const Segment(this.startMs, this.endMs, this.energy);

  int get durationMs => endMs - startMs;

  @override
  String toString() => 'Segment($startMs–$endMs ms, energy ${energy.toStringAsFixed(2)})';
}

/// One repetition (or attempt): its window and the moment of most movement.
class RepWindow {
  final int number; // 1-based, in the order they happened
  final int startMs;
  final int peakMs;
  final int endMs;
  const RepWindow(this.number, this.startMs, this.peakMs, this.endMs);
}

/// What was chosen to send, and why.
class FramePlan {
  final List<int> timesMs;

  /// Rep number for each frame, or null for the set-up frame.
  final List<int?> repGroups;

  /// Every rep found, even those not sampled.
  final List<RepWindow> reps;
  final List<Segment> segments;

  /// The person to crop to, and other moving regions that could have been them
  /// (largest first), so the user can say "no, that one".
  final NormRect subject;
  final List<NormRect> candidates;

  /// True when the plan is a guess: no clear motion, or no clear subject.
  final bool lowConfidence;
  final String? note;

  const FramePlan({
    required this.timesMs,
    required this.repGroups,
    required this.reps,
    required this.segments,
    required this.subject,
    this.candidates = const [],
    this.lowConfidence = false,
    this.note,
  });
}

/// The frames to send, ready to upload.
class SampledFrames {
  final FramePlan plan;
  final List<Uint8List> jpegs;
  const SampledFrames(this.plan, this.jpegs);

  int get count => jpegs.length;
  int get totalBytes => jpegs.fold(0, (t, f) => t + f.length);

  /// Seconds for each frame, as the backend wants them.
  List<double> get seconds => [for (final t in plan.timesMs) t / 1000];
}

/// Chooses the few frames of a clip that show the lifting, and crops them to
/// the person. All the decisions are made here in plain Dart so they can be
/// tested; the platform is only asked for pixels ([VideoTools]).
///
/// The steps are those of doc/video_analysis_plan.md, section 5: a cheap motion
/// map, the active stretches, the subject, the reps, fine sampling inside each
/// rep, then crop and encode.
class FrameSampler {
  final VideoTools tools;
  final SamplerConfig config;

  const FrameSampler(this.tools, {this.config = const SamplerConfig()});

  /// Look at the clip and decide which frames to send. Does the decoding for the
  /// motion map but encodes nothing; see [extract] for the pictures.
  Future<FramePlan> plan(String path, VideoInfo info) async {
    final times = mapTimes(info.durationMs, config.stepMs);
    final gray = await tools.grayFrames(path, times, width: config.grayWidth);
    return planFromGray(gray, times, info.durationMs, config);
  }

  /// Cut and encode the planned frames, cropped to [subject] (the plan's own by
  /// default).
  Future<SampledFrames> extract(
    String path,
    FramePlan plan, {
    NormRect? subject,
    int maxEdge = 768,
    double quality = 0.7,
  }) async {
    final jpegs = await tools.cropFrames(
      path,
      plan.timesMs,
      rect: subject ?? plan.subject,
      maxEdge: maxEdge,
      quality: quality,
    );
    return SampledFrames(plan, jpegs);
  }

  /// Plan and extract in one go.
  Future<SampledFrames> sample(String path, VideoInfo info) async =>
      extract(path, await plan(path, info));

  // ── The maths (static so tests can drive each stage) ─────────────────────────

  /// When to look: every [stepMs], and no more than 600 looks however long the
  /// clip, so a long clip costs a bounded amount.
  static List<int> mapTimes(int durationMs, int stepMs) {
    if (durationMs <= 0) return const [0];
    final step = math.max(stepMs, (durationMs / 600).ceil());
    return [for (var t = 0; t < durationMs; t += step) t];
  }

  /// The plan for a clip whose greyscale frames are [gray], looked at at [times].
  static FramePlan planFromGray(
    GrayFrames gray,
    List<int> times,
    int durationMs,
    SamplerConfig config,
  ) {
    final frames = gray.frames;
    if (frames.length < 3 || times.length != frames.length) {
      return fallbackPlan(durationMs, config, 'The clip is too short to find the movement.');
    }

    final stepMs = (times.last - times.first) ~/ math.max(1, times.length - 1);
    final curve = smooth(motionCurve(frames));
    final camera = cameraMoving(changedFraction(frames), config.cameraMoveFraction);
    final threshold = activeThreshold(curve, config, ignore: camera);
    if (threshold == null) {
      return fallbackPlan(durationMs, config, 'No clear movement was found.');
    }

    var segments = findSegments(curve, times, stepMs, threshold, config, ignore: camera);
    if (segments.isEmpty) {
      return fallbackPlan(durationMs, config, 'No clear movement was found.');
    }
    segments = focusWindow(segments, config.focusWindowMs);
    segments = capActive(segments, config.maxActiveMs);

    final reps = findReps(segments, curve, times, stepMs, threshold, config);
    final subjects = findSubjects(frames, gray.width, gray.height, times, segments);
    final subject = subjects.isEmpty ? NormRect.full : subjects.first;

    final picked = chooseFrames(reps, segments, durationMs, config);
    return FramePlan(
      timesMs: picked.$1,
      repGroups: picked.$2,
      reps: reps,
      segments: segments,
      subject: subject,
      candidates: subjects,
      // A crop that is the whole frame means the subject was not found.
      lowConfidence: subjects.isEmpty,
      note: subjects.isEmpty ? 'The person could not be picked out, so the whole frame is used.' : null,
    );
  }

  /// Evenly spaced frames, used when no movement is found. Marked low
  /// confidence so the result says so.
  static FramePlan fallbackPlan(int durationMs, SamplerConfig config, String note) {
    final n = config.fallbackFrames;
    final times = [
      for (var i = 0; i < n; i++) ((durationMs * (i + 0.5)) / n).round(),
    ];
    return FramePlan(
      timesMs: times,
      repGroups: List<int?>.filled(n, null),
      reps: const [],
      segments: const [],
      subject: NormRect.full,
      lowConfidence: true,
      note: note,
    );
  }

  /// Mean absolute change between each frame and the one before, 0–1. The first
  /// entry is 0.
  static List<double> motionCurve(List<Uint8List> frames) {
    final curve = List<double>.filled(frames.length, 0);
    for (var i = 1; i < frames.length; i++) {
      final a = frames[i - 1];
      final b = frames[i];
      final n = math.min(a.length, b.length);
      if (n == 0) continue;
      var sum = 0;
      for (var k = 0; k < n; k++) {
        final d = a[k] - b[k];
        sum += d < 0 ? -d : d;
      }
      curve[i] = sum / n / 255;
    }
    return curve;
  }

  /// The share of each frame's pixels that changed noticeably since the frame
  /// before (by at least [delta] of 255). A lifter changes a small part of the
  /// picture; the camera moving changes most of it. The first entry is 0.
  static List<double> changedFraction(List<Uint8List> frames, {int delta = 24}) {
    final out = List<double>.filled(frames.length, 0);
    for (var i = 1; i < frames.length; i++) {
      final a = frames[i - 1];
      final b = frames[i];
      final n = math.min(a.length, b.length);
      if (n == 0) continue;
      var changed = 0;
      for (var k = 0; k < n; k++) {
        final d = a[k] - b[k];
        if ((d < 0 ? -d : d) >= delta) changed++;
      }
      out[i] = changed / n;
    }
    return out;
  }

  /// Frames where the camera itself is moving: the changed share is above
  /// [limit], widened by two samples each side so the start and end of the move
  /// (which are gentler) are covered too.
  static List<bool> cameraMoving(List<double> changed, double limit) {
    final hit = [for (final c in changed) c > limit];
    return [
      for (var i = 0; i < hit.length; i++)
        hit.sublist(math.max(0, i - 2), math.min(hit.length, i + 3)).any((h) => h),
    ];
  }

  /// Keep the segments inside the [windowMs]-long stretch of the clip that holds
  /// the most separate bursts of movement, drop the rest; the amount of movement
  /// only breaks a tie. A set is a run of repeated bursts, so the run wins over a
  /// single bigger movement such as the lifter walking over to stop the phone.
  /// A clip shorter than the window is left alone.
  static List<Segment> focusWindow(List<Segment> segments, int windowMs) {
    if (segments.length < 2) return segments;
    final span = segments.last.endMs - segments.first.startMs;
    if (span <= windowMs) return segments;

    var best = <Segment>[];
    var bestEnergy = -1.0;
    for (final anchor in segments) {
      final inside = [
        for (final s in segments)
          if (s.startMs >= anchor.startMs && s.endMs <= anchor.startMs + windowMs) s,
      ];
      final energy = inside.fold<double>(0, (t, s) => t + s.energy);
      if (inside.length > best.length ||
          (inside.length == best.length && energy > bestEnergy)) {
        bestEnergy = energy;
        best = inside;
      }
    }
    return best.isEmpty ? segments : best;
  }

  /// A short moving average, so one noisy frame is not a movement.
  static List<double> smooth(List<double> curve, {int window = 3}) {
    final half = window ~/ 2;
    return [
      for (var i = 0; i < curve.length; i++)
        () {
          var sum = 0.0;
          var count = 0;
          for (var k = math.max(0, i - half); k <= math.min(curve.length - 1, i + half); k++) {
            sum += curve[k];
            count++;
          }
          return sum / count;
        }(),
    ];
  }

  /// The level above which a frame counts as active, or null when the clip has
  /// no movement worth the name.
  static double? activeThreshold(
    List<double> curve,
    SamplerConfig config, {
    List<bool>? ignore,
  }) {
    // Judged on the frames where the camera was steady, so one big camera move
    // does not set the bar so high that the lifting falls under it.
    final steady = [
      for (var i = 0; i < curve.length; i++)
        if (ignore == null || !ignore[i]) curve[i],
    ];
    if (steady.length < 3) return null;
    final sorted = [...steady]..sort();
    final resting = sorted[sorted.length ~/ 2];
    final strongest = sorted[(sorted.length * 0.97).floor().clamp(0, sorted.length - 1)];
    if (strongest < config.noiseFloor) return null;
    return math.max(config.noiseFloor, resting + config.activeFraction * (strongest - resting));
  }

  /// Stretches above [threshold], bursts close together joined, short blips
  /// dropped, and padded so the start and end of a movement are in view.
  static List<Segment> findSegments(
    List<double> curve,
    List<int> times,
    int stepMs,
    double threshold,
    SamplerConfig config, {
    List<bool>? ignore,
  }) {
    final runs = <(int, int)>[]; // inclusive sample indexes
    int? start;
    for (var i = 0; i < curve.length; i++) {
      final active = curve[i] >= threshold && !(ignore != null && ignore[i]);
      if (active && start == null) start = i;
      if (!active && start != null) {
        runs.add((start, i - 1));
        start = null;
      }
    }
    if (start != null) runs.add((start, curve.length - 1));

    // Join runs separated by a short pause.
    final gapSamples = math.max(1, config.mergeGapMs ~/ math.max(1, stepMs));
    final merged = <(int, int)>[];
    for (final r in runs) {
      if (merged.isNotEmpty && r.$1 - merged.last.$2 <= gapSamples) {
        merged[merged.length - 1] = (merged.last.$1, r.$2);
      } else {
        merged.add(r);
      }
    }

    final out = <Segment>[];
    final end = times.last;
    for (final r in merged) {
      final span = (r.$2 - r.$1 + 1) * stepMs;
      if (span < config.minSegmentMs) continue;
      var energy = 0.0;
      for (var i = r.$1; i <= r.$2; i++) {
        energy += curve[i];
      }
      out.add(Segment(
        math.max(0, times[r.$1] - config.paddingMs),
        math.min(end, times[r.$2] + stepMs + config.paddingMs),
        energy,
      ));
    }
    return out;
  }

  /// If there is more active time than [maxMs], keep the strongest stretches
  /// that fit, in time order.
  static List<Segment> capActive(List<Segment> segments, int maxMs) {
    final total = segments.fold<int>(0, (t, s) => t + s.durationMs);
    if (total <= maxMs) return segments;
    final byEnergy = [...segments]..sort((a, b) => b.energy.compareTo(a.energy));
    final kept = <Segment>[];
    var used = 0;
    for (final s in byEnergy) {
      if (used + s.durationMs > maxMs) continue;
      kept.add(s);
      used += s.durationMs;
    }
    kept.sort((a, b) => a.startMs.compareTo(b.startMs));
    return kept.isEmpty ? [byEnergy.first] : kept;
  }

  /// One rep per active stretch; a long stretch (a set done without pauses) is
  /// split at its movement peaks.
  static List<RepWindow> findReps(
    List<Segment> segments,
    List<double> curve,
    List<int> times,
    int stepMs,
    double threshold,
    SamplerConfig config,
  ) {
    final reps = <RepWindow>[];

    int peakIn(int fromMs, int toMs) {
      var best = fromMs;
      var bestValue = -1.0;
      for (var i = 0; i < times.length; i++) {
        if (times[i] < fromMs || times[i] > toMs) continue;
        if (curve[i] > bestValue) {
          bestValue = curve[i];
          best = times[i];
        }
      }
      return best;
    }

    for (final s in segments) {
      if (s.durationMs <= config.splitAboveMs) {
        reps.add(RepWindow(0, s.startMs, peakIn(s.startMs, s.endMs), s.endMs));
        continue;
      }

      // Local maxima above the threshold, at least minRepGapMs apart (the
      // stronger one wins when two are closer than that).
      final peaks = <int>[];
      for (var i = 1; i < times.length - 1; i++) {
        if (times[i] < s.startMs || times[i] > s.endMs) continue;
        if (curve[i] < threshold || curve[i] < curve[i - 1] || curve[i] < curve[i + 1]) continue;
        if (peaks.isNotEmpty && times[i] - peaks.last < config.minRepGapMs) {
          final last = times.indexOf(peaks.last);
          if (curve[i] > curve[last]) peaks[peaks.length - 1] = times[i];
          continue;
        }
        peaks.add(times[i]);
      }
      if (peaks.length < 2) {
        reps.add(RepWindow(0, s.startMs, peaks.isEmpty ? peakIn(s.startMs, s.endMs) : peaks.first, s.endMs));
        continue;
      }
      for (var k = 0; k < peaks.length; k++) {
        final from = k == 0 ? s.startMs : (peaks[k - 1] + peaks[k]) ~/ 2;
        final to = k == peaks.length - 1 ? s.endMs : (peaks[k] + peaks[k + 1]) ~/ 2;
        reps.add(RepWindow(0, from, peaks[k], to));
      }
    }

    return [
      for (var i = 0; i < reps.length; i++)
        RepWindow(i + 1, reps[i].startMs, reps[i].peakMs, reps[i].endMs),
    ];
  }

  /// Pick the frames: one set-up frame before the first rep, then a handful
  /// inside each rep (start, between, the extreme, between, end). With many
  /// reps, the first, some from the middle and the last are used.
  static (List<int>, List<int?>) chooseFrames(
    List<RepWindow> reps,
    List<Segment> segments,
    int durationMs,
    SamplerConfig config,
  ) {
    final times = <int>[];
    final groups = <int?>[];
    final firstStart = reps.first.startMs;

    // Set-up: a moment before the first movement, where the starting position
    // can be seen. If the movement starts at once, the very start.
    times.add(math.max(0, firstStart - 1000));
    groups.add(null);

    final room = config.frameBudget - 1;
    var perRep = math.min(5, room ~/ reps.length);
    var used = reps;
    if (perRep < 3) {
      perRep = 3;
      final count = math.max(1, room ~/ perRep);
      used = [for (final i in _spread(reps.length, count)) reps[i]];
    }

    for (final rep in used) {
      final marks = switch (perRep) {
        >= 5 => [
            rep.startMs,
            (rep.startMs + rep.peakMs) ~/ 2,
            rep.peakMs,
            (rep.peakMs + rep.endMs) ~/ 2,
            rep.endMs,
          ],
        4 => [rep.startMs, rep.peakMs - (rep.peakMs - rep.startMs) ~/ 3, rep.peakMs, rep.endMs],
        _ => [rep.startMs, rep.peakMs, rep.endMs],
      };
      for (final t in marks) {
        final int clamped = t.clamp(0, math.max(0, durationMs - 1)).toInt();
        // Frames closer than 80 ms are nearly the same picture.
        if (times.any((x) => (x - clamped).abs() < 80)) continue;
        times.add(clamped);
        groups.add(rep.number);
      }
    }

    // Time order, keeping each frame's rep with it.
    final order = List<int>.generate(times.length, (i) => i)
      ..sort((a, b) => times[a].compareTo(times[b]));
    final sortedTimes = [for (final i in order) times[i]];
    final sortedGroups = [for (final i in order) groups[i]];
    if (sortedTimes.length > config.frameBudget) {
      return (
        sortedTimes.sublist(0, config.frameBudget),
        sortedGroups.sublist(0, config.frameBudget),
      );
    }
    return (sortedTimes, sortedGroups);
  }

  /// [count] indexes spread evenly over 0..length-1, always including the first
  /// and the last.
  static List<int> _spread(int length, int count) {
    if (count >= length) return List.generate(length, (i) => i);
    if (count == 1) return [0];
    return [
      for (var i = 0; i < count; i++) ((i * (length - 1)) / (count - 1)).round(),
    ];
  }

  /// The moving regions, largest first, each as a rectangle with a margin.
  ///
  /// Movement is summed over the active stretches into a heat map; the strong
  /// cells are grouped into connected regions. In a busy gym the biggest region
  /// is usually the lifter, but not always, so every sizeable region is
  /// returned and the caller can offer the choice.
  static List<NormRect> findSubjects(
    List<Uint8List> frames,
    int width,
    int height,
    List<int> times,
    List<Segment> segments,
  ) {
    final size = width * height;
    if (size == 0) return const [];

    final heat = List<double>.filled(size, 0);
    var used = 0;
    for (var i = 1; i < frames.length; i++) {
      final t = times[i];
      if (!segments.any((s) => t >= s.startMs && t <= s.endMs)) continue;
      final a = frames[i - 1];
      final b = frames[i];
      if (a.length < size || b.length < size) continue;
      // Only a real change counts. Hand-held footage flickers a little all over
      // the picture, and summing that spreads the "movement" to the whole frame.
      for (var k = 0; k < size; k++) {
        final d = a[k] - b[k];
        if ((d < 0 ? -d : d) >= 32) heat[k] += 1;
      }
      used++;
    }
    if (used == 0) return const [];

    final peak = heat.reduce(math.max);
    if (peak <= 0) return const [];

    // Cells well above the noise, then connected regions of them.
    final hot = List<bool>.generate(size, (k) => heat[k] >= peak * 0.35);
    final seen = List<bool>.filled(size, false);
    final regions = <({int count, int minX, int minY, int maxX, int maxY})>[];

    for (var start = 0; start < size; start++) {
      if (!hot[start] || seen[start]) continue;
      var count = 0, minX = width, minY = height, maxX = 0, maxY = 0;
      final stack = <int>[start];
      seen[start] = true;
      while (stack.isNotEmpty) {
        final k = stack.removeLast();
        final x = k % width, y = k ~/ width;
        count++;
        minX = math.min(minX, x);
        maxX = math.max(maxX, x);
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
        // Reaching three cells, so thin gaps in a person don't split them.
        for (var dy = -3; dy <= 3; dy++) {
          for (var dx = -3; dx <= 3; dx++) {
            final nx = x + dx, ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
            final n = ny * width + nx;
            if (hot[n] && !seen[n]) {
              seen[n] = true;
              stack.add(n);
            }
          }
        }
      }
      regions.add((count: count, minX: minX, minY: minY, maxX: maxX, maxY: maxY));
    }

    // A person moving is often several regions (an arm, the bar, a leg) with
    // still cloth between them. Regions whose boxes are close are one subject.
    // Close enough to be one body, but not so close that a foreground object
    // at the edge of the frame (a plate, a rack) gets joined to the lifter.
    final joinGap = math.max(2, (width * 0.025).round());
    var merged = true;
    while (merged) {
      merged = false;
      outer:
      for (var i = 0; i < regions.length; i++) {
        for (var j = i + 1; j < regions.length; j++) {
          final a = regions[i], b = regions[j];
          final gapX = math.max(a.minX, b.minX) - math.min(a.maxX, b.maxX) - 1;
          final gapY = math.max(a.minY, b.minY) - math.min(a.maxY, b.maxY) - 1;
          if (gapX <= joinGap && gapY <= joinGap) {
            regions[i] = (
              count: a.count + b.count,
              minX: math.min(a.minX, b.minX),
              minY: math.min(a.minY, b.minY),
              maxX: math.max(a.maxX, b.maxX),
              maxY: math.max(a.maxY, b.maxY),
            );
            regions.removeAt(j);
            merged = true;
            break outer;
          }
        }
      }
    }

    // A region has to be a real object, not a few flickering cells.
    final minCount = math.max(6, size ~/ 400);
    final real = regions.where((r) => r.count >= minCount).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final out = <NormRect>[];
    for (final r in real.take(3)) {
      final w = (r.maxX - r.minX + 1) / width;
      final h = (r.maxY - r.minY + 1) / height;
      // A margin so the bar, the feet and the head are not cut off.
      final mx = math.max(0.06, w * 0.25);
      final my = math.max(0.06, h * 0.2);
      final rect = NormRect(
        (r.minX / width - mx).clamp(0.0, 1.0),
        (r.minY / height - my).clamp(0.0, 1.0),
        ((r.maxX + 1) / width + mx).clamp(0.0, 1.0),
        ((r.maxY + 1) / height + my).clamp(0.0, 1.0),
      );
      // Nearly the whole frame is no crop at all; a sliver is not a person.
      if (rect.area > 0.85 || rect.width < 0.1 || rect.height < 0.1) continue;
      out.add(rect);
    }
    return out;
  }
}
