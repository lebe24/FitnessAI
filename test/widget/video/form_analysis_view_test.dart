import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/ui/features/video/views/form_analysis_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The benchmark result from doc/video_analysis_plan.md, section 6: a deadlift
/// filmed from behind, with the form score the camera could not support.
const _benchmark = FormAnalysis(
  exercise: 'conventional deadlift',
  cameraView: CameraView.rear,
  confidence: Confidence.low,
  overallScore: 7,
  stanceScore: 8,
  formScore: null,
  tempoScore: 5,
  summary: 'Stable set-up and clean lockouts. The bar is dropped rather than lowered.',
  repsCompleted: 3,
  repAttempts: 4,
  repNotes: '4th attempt: bar stayed on the floor',
  stance: ['Feet about hip-width and planted through every rep'],
  tempo: ['Lift takes about half a second', 'Bar reaches the floor in under a second'],
  cues: [
    FormCue(severity: CueSeverity.low, issue: 'Grip looks uneven', fix: 'Check your hand spacing.'),
    FormCue(
        severity: CueSeverity.high,
        issue: 'Bar lowered very fast',
        fix: 'Control the descent: hips back, bar close to the legs.'),
  ],
  goodPoints: ['Full lockout every rep', 'Consistent starting position'],
  limitations: ['Filmed from behind: spine position and bar path cannot be judged'],
);

Widget _view(FormAnalysis a, {String name = 'Deadlift', VoidCallback? onRerun}) => MaterialApp(
      home: Scaffold(
        body: FormAnalysisView(
          exerciseName: name,
          analysis: a,
          onClose: () {},
          onRerun: onRerun,
        ),
      ),
    );

Future<void> _show(WidgetTester t, FormAnalysis a, {VoidCallback? onRerun, String name = 'Deadlift'}) async {
  await t.binding.setSurfaceSize(const Size(430, 2400));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(_view(a, onRerun: onRerun, name: name));
  await t.pump();
}

void main() {
  group('the benchmark result (rear view, low confidence)', () {
    testWidgets('shows the rating, the band and the camera view', (t) async {
      await _show(t, _benchmark);
      expect(find.bySemanticsLabel('Overall rating 7 out of 10'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Filmed from behind'), findsOneWidget);
      expect(find.text('Low confidence'), findsOneWidget);
    });

    testWidgets('says plainly that form could not be judged, and does not invent a number', (t) async {
      await _show(t, _benchmark);
      expect(find.text("Can't judge from this angle"), findsOneWidget);
      expect(find.text('Form'), findsOneWidget);
      expect(find.text('8/10'), findsOneWidget, reason: 'stance');
      expect(find.text('5/10'), findsOneWidget, reason: 'tempo');
    });

    testWidgets('explains the limits of a low-confidence result', (t) async {
      await _show(t, _benchmark);
      expect(find.textContaining('film side-on'), findsOneWidget);
      expect(find.text("What I couldn't judge"), findsOneWidget);
      expect(find.textContaining('spine position and bar path cannot be judged'), findsOneWidget);
    });

    testWidgets('reports attempts as well as reps', (t) async {
      await _show(t, _benchmark);
      expect(find.text('3 clean reps · 4 attempts'), findsOneWidget);
      expect(find.text('4th attempt: bar stayed on the floor'), findsOneWidget);
    });

    testWidgets('lists the most important cue first', (t) async {
      await _show(t, _benchmark);
      final high = t.getTopLeft(find.text('Bar lowered very fast')).dy;
      final low = t.getTopLeft(find.text('Grip looks uneven')).dy;
      expect(high, lessThan(low));
      expect(find.text('IMPORTANT'), findsOneWidget);
      expect(find.text('MINOR'), findsOneWidget);
    });

    testWidgets('shows what looked good, and the disclaimer', (t) async {
      await _show(t, _benchmark);
      expect(find.text('Full lockout every rep'), findsOneWidget);
      expect(find.textContaining('not medical advice'), findsOneWidget);
    });
  });

  group('a confident side-view result', () {
    const good = FormAnalysis(
      cameraView: CameraView.side,
      confidence: Confidence.high,
      overallScore: 9,
      stanceScore: 9,
      formScore: 9,
      tempoScore: 8,
      summary: 'Textbook set.',
      repsCompleted: 5,
      repAttempts: 5,
    );

    testWidgets('has no low-confidence warning and no "couldn\'t judge" section', (t) async {
      await _show(t, good);
      expect(find.text('Excellent'), findsOneWidget);
      expect(find.text('High confidence'), findsOneWidget);
      expect(find.textContaining('film side-on'), findsNothing);
      expect(find.text("What I couldn't judge"), findsNothing);
      expect(find.text("Can't judge from this angle"), findsNothing);
      expect(find.text('What to work on'), findsNothing);
    });

    testWidgets('a clean set of five reads "5 clean reps · 5 attempts"', (t) async {
      await _show(t, good);
      expect(find.text('5 clean reps · 5 attempts'), findsOneWidget);
    });
  });

  group('edge cases', () {
    testWidgets('no score at all reads "Not rated"', (t) async {
      await _show(t, const FormAnalysis(cameraView: CameraView.unclear));
      expect(find.text('Not rated'), findsOneWidget);
      expect(find.text("Can't judge from this angle"), findsNWidgets(3));
    });

    testWidgets('a low score is "Worth correcting"', (t) async {
      await _show(t, const FormAnalysis(overallScore: 3, confidence: Confidence.high, formScore: 3));
      expect(find.text('Worth correcting'), findsOneWidget);
    });

    testWidgets('a different exercise from the one asked for is called out', (t) async {
      await _show(
        t,
        const FormAnalysis(
            exercise: 'romanian deadlift', exerciseMatchesRequest: false, overallScore: 6),
        name: 'Squat',
      );
      expect(find.textContaining('looks like romanian deadlift, not Squat'), findsOneWidget);
    });

    testWidgets('a mismatch with no name says so without a blank', (t) async {
      await _show(t, const FormAnalysis(exerciseMatchesRequest: false), name: 'Squat');
      expect(find.textContaining("doesn't look like Squat"), findsOneWidget);
    });

    testWidgets('Run again is offered only when the caller allows it', (t) async {
      await _show(t, _benchmark);
      expect(find.text('Run again'), findsNothing);

      var reruns = 0;
      await _show(t, _benchmark, onRerun: () => reruns++);
      await t.tap(find.text('Run again'));
      expect(reruns, 1);
    });

    testWidgets('long text does not overflow a small phone', (t) async {
      await t.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(_view(FormAnalysis(
        overallScore: 6,
        summary: 'x' * 400,
        cues: [FormCue(severity: CueSeverity.medium, issue: 'y' * 300, fix: 'z' * 300)],
        form: ['w' * 300],
        formScore: 6,
      )));
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });
}
