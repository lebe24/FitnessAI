import 'dart:typed_data';

import 'package:fitness/data/services/video/frame_sampler.dart';
import 'package:fitness/data/services/video/video_tools.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/synthetic_clip.dart';

FramePlan _plan(SyntheticClip clip, {SamplerConfig config = const SamplerConfig()}) =>
    FrameSampler.planFromGray(clip.frames(), clip.times, clip.durationMs, config);

void main() {
  group('a clip with three separate reps', () {
    final clip = SyntheticClip(20000, bursts: [(5000, 5750), (9000, 9750), (13000, 13750)]);
    late FramePlan plan;
    setUpAll(() => plan = _plan(clip));

    test('finds the three active stretches and ignores the idle time', () {
      expect(plan.segments, hasLength(3));
      final starts = plan.segments.map((s) => s.startMs).toList();
      for (final (i, want) in [5000, 9000, 13000].indexed) {
        expect((starts[i] - want).abs(), lessThan(700), reason: 'segment $i at ${starts[i]}');
      }
      final active = plan.segments.fold<int>(0, (t, s) => t + s.durationMs);
      expect(active, lessThan(6000), reason: '20 s clip, ~2.3 s of movement');
    });

    test('counts three reps, in order', () {
      expect(plan.reps.map((r) => r.number), [1, 2, 3]);
      for (final r in plan.reps) {
        expect(r.startMs, lessThanOrEqualTo(r.peakMs));
        expect(r.peakMs, lessThanOrEqualTo(r.endMs));
      }
    });

    test('sends at most the budget, in time order, labelled by rep', () {
      expect(plan.timesMs.length, lessThanOrEqualTo(12));
      expect(plan.timesMs.length, plan.repGroups.length);
      expect([...plan.timesMs]..sort(), plan.timesMs);
      expect(plan.timesMs.toSet().length, plan.timesMs.length, reason: 'no duplicate times');
      for (final rep in [1, 2, 3]) {
        expect(plan.repGroups.where((g) => g == rep).length, greaterThanOrEqualTo(3),
            reason: 'rep $rep sampled finely');
      }
    });

    test('starts with a set-up frame from before the first rep', () {
      expect(plan.repGroups.first, isNull);
      expect(plan.timesMs.first, lessThan(plan.segments.first.startMs));
    });

    test('every sampled frame falls inside a rep, apart from the set-up one', () {
      for (var i = 1; i < plan.timesMs.length; i++) {
        final t = plan.timesMs[i];
        expect(plan.segments.any((s) => t >= s.startMs && t <= s.endMs), isTrue, reason: '$t ms');
      }
    });

    test('crops to the lifter, with a margin', () {
      final s = plan.subject;
      // The lifter occupies x 6..23 of 40, y 10..19 of 30 while moving.
      expect(s.left, lessThan(7 / kClipW));
      expect(s.right, greaterThan(18 / kClipW));
      expect(s.top, lessThan(10 / kClipH));
      expect(s.bottom, greaterThan(19 / kClipH));
      expect(s.area, lessThan(0.85));
      expect(plan.lowConfidence, isFalse);
    });
  });

  group('a busy gym', () {
    final clip = SyntheticClip(20000, bursts: [(5000, 5750), (9000, 9750)], bystander: true);

    test('picks the bigger, stronger mover as the lifter and offers the other', () {
      final plan = _plan(clip);
      final s = plan.subject;
      // The lifter is on the left of the frame; the bystander wiggles at the right edge.
      expect(s.left, lessThan(0.3));
      expect(s.right, lessThan(0.9));
    });
  });

  group('a set done without pauses', () {
    test('is split into its reps at the movement peaks', () {
      final plan = _plan(SyntheticClip(16000, periodMs: 3000));
      expect(plan.reps.length, inInclusiveRange(4, 7), reason: '16 s at one rep every 3 s');
      expect(plan.timesMs.length, lessThanOrEqualTo(12));
      // Many reps: the first, some middle ones and the last are sampled.
      expect(plan.repGroups.whereType<int>().first, 1);
      expect(plan.repGroups.whereType<int>().last, plan.reps.last.number);
    });
  });

  group('the camera moving (the benchmark clip\'s ending)', () {
    // Lifts at 6, 11 and 16 s; then the lifter picks the phone up and the whole
    // picture changes for the last few seconds, far stronger than any lift.
    final clip = SyntheticClip(
      24000,
      bursts: [(6000, 6750), (11000, 11750), (16000, 16750)],
      cameraMoves: [(20500, 23800)],
    );

    test('does not hide the lifts behind it', () {
      final plan = _plan(clip);
      expect(plan.lowConfidence, isFalse);
      expect(plan.reps, hasLength(3), reason: '${plan.segments}');
      for (final seg in plan.segments) {
        expect(seg.startMs, lessThan(19000), reason: 'nothing from the camera move: $seg');
      }
    });

    test('is never counted as activity itself', () {
      final plan = _plan(clip);
      for (final t in plan.timesMs) {
        expect(t, lessThan(19000));
      }
    });

    test('is recognised by how much of the frame changed, not by how strongly', () {
      final frames = clip.frames().frames;
      final changed = FrameSampler.changedFraction(frames);
      final camera = FrameSampler.cameraMoving(changed, 0.15);
      final times = clip.times;
      for (var i = 0; i < times.length; i++) {
        if (times[i] >= 21000 && times[i] <= 23500) expect(camera[i], isTrue, reason: '${times[i]}');
        if (times[i] >= 5000 && times[i] <= 17500) expect(camera[i], isFalse, reason: '${times[i]}');
      }
    });

    test('a lifter on its own is never mistaken for a camera move', () {
      final frames = SyntheticClip(20000, bursts: [(5000, 5750), (9000, 9750)]).frames().frames;
      final changed = FrameSampler.changedFraction(frames);
      expect(changed.reduce((a, b) => a > b ? a : b), lessThan(0.15));
    });
  });

  group('the busiest stretch', () {
    Segment seg(int start, int end, [double e = 1]) => Segment(start, end, e);

    test('a run of reps beats one bigger movement elsewhere', () {
      // Five lifts 5 s apart, and one large movement at the end (walking to the phone).
      final kept = FrameSampler.focusWindow([
        seg(92600, 93900, .06), seg(97800, 99000, .06), seg(103200, 104500, .05),
        seg(110200, 112900, .14), seg(115800, 117600, .08),
        seg(139300, 141800, .17),
      ], 40000);
      expect(kept.map((x) => x.startMs), [92600, 97800, 103200, 110200, 115800]);
    });

    test('activity at the very start of the clip is left out', () {
      final kept = FrameSampler.focusWindow([
        seg(0, 1700, .1), seg(3000, 4200, .05),
        seg(60000, 61000), seg(65000, 66000), seg(70000, 71000),
      ], 40000);
      expect(kept.map((x) => x.startMs), [60000, 65000, 70000]);
    });

    test('equal counts are decided by the amount of movement', () {
      final kept = FrameSampler.focusWindow([
        seg(0, 1000, .1), seg(5000, 6000, .1),
        seg(100000, 101000, .9), seg(105000, 106000, .9),
      ], 40000);
      expect(kept.map((x) => x.startMs), [100000, 105000]);
    });

    test('a clip shorter than the window is left alone', () {
      final all = [seg(0, 1000), seg(20000, 21000), seg(35000, 36000)];
      expect(FrameSampler.focusWindow(all, 40000), all);
    });

    test('one or no segments pass straight through', () {
      expect(FrameSampler.focusWindow(const [], 40000), isEmpty);
      expect(FrameSampler.focusWindow([seg(5, 10)], 40000), hasLength(1));
    });
  });

  group('picking the person', () {
    test('hand-held flicker all over the picture does not widen the box', () {
      // The lifter moves in the middle; the whole frame also flickers a little.
      final clip = SyntheticClip(20000, bursts: [(5000, 5750), (9000, 9750)]);
      final plan = _plan(clip);
      expect(plan.subject.area, lessThan(0.7));
      expect(plan.lowConfidence, isFalse);
    });

    test('something big and still at the edge of the frame is not joined to the lifter', () {
      // A bystander wiggling at the far right must not stretch the box to it.
      final plan = _plan(SyntheticClip(20000, bursts: [(5000, 5750), (9000, 9750)], bystander: true));
      expect(plan.subject.right, lessThan(0.9));
    });
  });

  group('no clear movement', () {
    test('a still clip falls back to evenly spaced frames, marked low confidence', () {
      final plan = _plan(SyntheticClip(20000));
      expect(plan.lowConfidence, isTrue);
      expect(plan.timesMs, hasLength(8));
      expect(plan.segments, isEmpty);
      expect(plan.subject.area, 1, reason: 'the whole frame');
      expect(plan.note, isNotNull);
      // Spread across the clip, not bunched.
      expect(plan.timesMs.first, lessThan(4000));
      expect(plan.timesMs.last, greaterThan(16000));
    });

    test('a clip too short to measure falls back too', () {
      final plan = FrameSampler.planFromGray(
        GrayFrames(width: 4, height: 4, frames: [Uint8List(16), Uint8List(16)]),
        [0, 125],
        250,
        const SamplerConfig(),
      );
      expect(plan.lowConfidence, isTrue);
    });
  });

  group('the stages', () {
    test('mapTimes looks every step, and no more than 600 times', () {
      expect(FrameSampler.mapTimes(1000, 125), [0, 125, 250, 375, 500, 625, 750, 875]);
      expect(FrameSampler.mapTimes(10 * 60 * 1000, 125).length, lessThanOrEqualTo(600));
      expect(FrameSampler.mapTimes(0, 125), [0]);
    });

    test('motionCurve is the mean change between frames', () {
      final a = Uint8List.fromList([0, 0, 0, 0]);
      final b = Uint8List.fromList([255, 255, 0, 0]);
      expect(FrameSampler.motionCurve([a, b, b]), [0, 0.5, 0]);
    });

    test('smooth leaves a flat line flat and spreads a spike', () {
      expect(FrameSampler.smooth([1, 1, 1, 1]), [1, 1, 1, 1]);
      final s = FrameSampler.smooth([0, 0, 3, 0, 0]);
      expect(s[2], 1);
      expect(s[1], 1);
    });

    test('a clip with nothing in it has no threshold', () {
      expect(FrameSampler.activeThreshold(List.filled(50, 0.002), const SamplerConfig()), isNull);
      expect(FrameSampler.activeThreshold([0.01, 0.02], const SamplerConfig()), isNull);
    });

    test('over the active limit, the strongest stretches are kept, in time order', () {
      final kept = FrameSampler.capActive(const [
        Segment(0, 20000, 1),
        Segment(30000, 50000, 9),
        Segment(60000, 70000, 5),
      ], 30000);
      expect(kept.map((s) => s.startMs), [30000, 60000]);
    });

    test('under the limit, nothing is dropped', () {
      const segs = [Segment(0, 1000, 1), Segment(5000, 6000, 2)];
      expect(FrameSampler.capActive(segs, 30000), segs);
    });

    test('one huge stretch is still kept', () {
      final kept = FrameSampler.capActive(const [Segment(0, 90000, 1)], 30000);
      expect(kept, hasLength(1));
    });
  });

  group('frame choice', () {
    const config = SamplerConfig();
    final segs = [const Segment(0, 100000, 1)];

    List<RepWindow> reps(int n) => [
          for (var i = 0; i < n; i++)
            RepWindow(i + 1, 5000 + i * 4000, 5600 + i * 4000, 6200 + i * 4000),
        ];

    test('one rep gets five frames and a set-up frame', () {
      final (times, groups) = FrameSampler.chooseFrames(reps(1), segs, 60000, config);
      expect(groups.where((g) => g == 1), hasLength(5));
      expect(groups.where((g) => g == null), hasLength(1));
      expect(times.length, 6);
    });

    test('never exceeds the budget however many reps', () {
      for (final n in [2, 3, 5, 8, 12, 30]) {
        final (times, groups) = FrameSampler.chooseFrames(reps(n), segs, 200000, config);
        expect(times.length, lessThanOrEqualTo(config.frameBudget), reason: '$n reps');
        expect(times.length, groups.length);
        expect([...times]..sort(), times);
      }
    });

    test('with many reps the first and the last are always in', () {
      final (_, groups) = FrameSampler.chooseFrames(reps(20), segs, 200000, config);
      expect(groups, contains(1));
      expect(groups, contains(20));
    });

    test('frames are kept inside the clip', () {
      final (times, _) = FrameSampler.chooseFrames(
          [const RepWindow(1, 0, 100, 500)], segs, 400, config);
      expect(times.every((t) => t >= 0 && t < 400), isTrue);
    });
  });

  group('through the tools', () {
    test('asks the platform for the map, then for the chosen frames only', () async {
      final clip = SyntheticClip(20000, bursts: [(5000, 5750), (9000, 9750)]);
      final tools = FakeVideoTools(clip: clip);
      final sampler = FrameSampler(tools);
      final sampled = await sampler.sample('/clip.mp4', const VideoInfo(durationMs: 20000, width: 720, height: 1280));

      expect(tools.grayCalls, 1);
      expect(tools.cropCalls, 1);
      expect(tools.lastCropTimes, sampled.plan.timesMs);
      expect(tools.lastRect, sampled.plan.subject);
      expect(sampled.count, sampled.plan.timesMs.length);
      expect(sampled.seconds.first, closeTo(sampled.plan.timesMs.first / 1000, 1e-9));
      expect(sampled.totalBytes, greaterThan(0));
    });

    test('can be re-cropped to a different person without decoding again', () async {
      final clip = SyntheticClip(20000, bursts: [(5000, 5750)]);
      final tools = FakeVideoTools(clip: clip);
      final sampler = FrameSampler(tools);
      final plan = await sampler.plan('/clip.mp4', const VideoInfo(durationMs: 20000, width: 720, height: 1280));
      const other = NormRect(0.5, 0.5, 0.9, 0.9);
      await sampler.extract('/clip.mp4', plan, subject: other);
      expect(tools.grayCalls, 1);
      expect(tools.lastRect, other);
    });
  });
}
