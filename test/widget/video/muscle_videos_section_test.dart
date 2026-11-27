import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/domain/models/muscle.dart';
import 'package:fitness/ui/features/video/views/muscle_videos_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/video_test_env.dart';

void main() {
  late VideoTestEnv env;
  final now = DateTime(2026, 11, 2, 12);
  final biceps = Muscle.bySlug('biceps')!;

  setUp(() async => env = await VideoTestEnv.create());
  tearDown(() async => env.dispose());

  Future<void> show(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MuscleVideosSection(muscle: biceps, storage: env.storage, now: now),
        ),
      ),
    ));
    await t.pump();
    await t.pump();
  }

  FormAnalysis rated(int s) => FormAnalysis(overallScore: s, confidence: Confidence.high);

  testWidgets('says what will appear here when there is nothing yet', (t) async {
    await show(t);
    expect(find.textContaining('Videos you record against biceps exercises'), findsOneWidget);
  });

  testWidgets('lists videos saved against this muscle, with exercise and date', (t) async {
    await t.runAsync(() async {
      await env.add('Pull-Ups', muscles: ['upper-back', 'biceps'], at: DateTime(2026, 11, 1));
      await env.add('Hammer Curl', muscles: ['biceps'], at: DateTime(2026, 10, 25));
      await env.add('Squat', muscles: ['quadriceps']);
    });
    await show(t);
    expect(find.text('Pull-Ups'), findsOneWidget);
    expect(find.text('Hammer Curl'), findsOneWidget);
    expect(find.text('Squat'), findsNothing, reason: 'trains quads, not biceps');
    expect(find.textContaining('Yesterday'), findsOneWidget);
  });

  testWidgets('newest first', (t) async {
    await t.runAsync(() async {
      await env.add('Old Curl', muscles: ['biceps'], at: DateTime(2026, 9, 1));
      await env.add('New Curl', muscles: ['biceps'], at: DateTime(2026, 11, 1));
    });
    await show(t);
    expect(t.getTopLeft(find.text('New Curl')).dy, lessThan(t.getTopLeft(find.text('Old Curl')).dy));
  });

  testWidgets('shows each rating, or "Not analysed"', (t) async {
    await t.runAsync(() async {
      await env.add('Pull-Ups', muscles: ['biceps'], analysis: rated(8));
      await env.add('Hammer Curl', muscles: ['biceps']);
    });
    await show(t);
    expect(find.text('8/10'), findsOneWidget);
    expect(find.text('Not analysed'), findsOneWidget);
  });

  group('the trend', () {
    testWidgets('appears from three rated videos and says which way it moved', (t) async {
      await t.runAsync(() async {
        await env.add('Curl', muscles: ['biceps'], at: DateTime(2026, 10, 1), analysis: rated(5));
        await env.add('Curl', muscles: ['biceps'], at: DateTime(2026, 10, 10), analysis: rated(6));
        await env.add('Curl', muscles: ['biceps'], at: DateTime(2026, 10, 20), analysis: rated(8));
      });
      await show(t);
      expect(find.text('Form rating trend'), findsOneWidget);
      expect(find.textContaining('5 → 8'), findsOneWidget);
      expect(find.textContaining('Up 3'), findsOneWidget);
    });

    testWidgets('is not drawn for fewer than three rated videos', (t) async {
      await t.runAsync(() async {
        await env.add('Curl', muscles: ['biceps'], at: DateTime(2026, 10, 1), analysis: rated(5));
        await env.add('Curl', muscles: ['biceps'], at: DateTime(2026, 10, 10), analysis: rated(6));
        await env.add('Curl', muscles: ['biceps'], at: DateTime(2026, 10, 20));
      });
      await show(t);
      expect(find.text('Form rating trend'), findsNothing);
    });

    testWidgets('says "Down" and "Steady" truthfully', (t) async {
      await t.runAsync(() async {
        await env.add('Curl', muscles: ['biceps'], at: DateTime(2026, 10, 1), analysis: rated(8));
        await env.add('Curl', muscles: ['biceps'], at: DateTime(2026, 10, 10), analysis: rated(7));
        await env.add('Curl', muscles: ['biceps'], at: DateTime(2026, 10, 20), analysis: rated(6));
      });
      await show(t);
      expect(find.textContaining('Down 2'), findsOneWidget);
    });
  });

  testWidgets('deleting a video removes it here too', (t) async {
    late ExerciseVideo v;
    await t.runAsync(() async => v = await env.add('Pull-Ups', muscles: ['biceps']));
    await show(t);
    expect(find.text('Pull-Ups'), findsOneWidget);
    await t.runAsync(() => env.storage.delete(v.id));
    await t.pump();
    await t.pump();
    expect(find.text('Pull-Ups'), findsNothing);
    expect(find.textContaining('Videos you record against'), findsOneWidget);
  });
}
