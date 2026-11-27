import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/ui/features/video/views/video_catalog_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ExerciseVideo _video({String name = 'Incline Dumbbell Press', bool analysed = false, int ms = 24000}) =>
    ExerciseVideo(
      id: 'a',
      recordedAt: DateTime(2025, 11, 18),
      durationMs: ms,
      sizeBytes: 1024,
      exerciseName: name,
      exerciseKey: 'k',
      muscles: const [],
      filePath: 'x/a.mp4',
      thumbnailPath: 'x/a.jpg',
      analysis: analysed ? FormAnalysis(overallScore: 8, confidence: Confidence.high) : null,
    );

class _NoFiles extends ExerciseVideoStorage {}

Future<void> _pump(WidgetTester t, ExerciseVideo v, {VoidCallback? onTap, double width = 167}) async {
  await t.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: VideoCatalogCard(video: v, storage: _NoFiles(), onTap: onTap ?? () {}),
        ),
      ),
    ),
  ));
  await t.pump();
}

void main() {
  testWidgets('shows the exercise, the date and the length', (t) async {
    await _pump(t, _video());
    expect(find.text('Incline Dumbbell Press'), findsOneWidget);
    expect(find.text('Nov 18 · 0:24'), findsOneWidget);
    // The length is also on the picture.
    expect(find.text('0:24'), findsOneWidget);
  });

  testWidgets('the badge appears only once the form is checked', (t) async {
    await _pump(t, _video());
    expect(find.text('FORM CHECKED'), findsNothing);

    await _pump(t, _video(analysed: true));
    expect(find.text('FORM CHECKED'), findsOneWidget);
  });

  testWidgets('a tap calls back', (t) async {
    var taps = 0;
    await _pump(t, _video(), onTap: () => taps++);
    await t.tap(find.text('Incline Dumbbell Press'));
    expect(taps, 1);
  });

  testWidgets('a long name stays on one line and does not overflow', (t) async {
    await _pump(t, _video(name: 'Single-arm Dumbbell Romanian Deadlift with a long pause', analysed: true), width: 140);
    expect(t.takeException(), isNull);
    expect(t.getSize(find.byType(VideoCatalogCard)).height, kVideoCatalogCardHeight);
  });

  testWidgets('is described to screen readers in one phrase', (t) async {
    final handle = t.ensureSemantics();
    await _pump(t, _video(analysed: true));
    expect(find.bySemanticsLabel('Incline Dumbbell Press, Nov 18, 0:24, form checked'), findsOneWidget);
    handle.dispose();
  });
}
