import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_service.dart';
import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/ui/features/profile/views/workout_videos_page.dart';
import 'package:fitness/ui/features/video/views/video_catalog_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/recording_analytics.dart';
import '../../support/video_test_env.dart';

void main() {
  late VideoTestEnv env;
  setUp(() async => env = await VideoTestEnv.create());
  tearDown(() async => env.dispose());

  Future<void> show(WidgetTester t) async {
    await t.pumpWidget(MaterialApp(home: WorkoutVideosPage(storage: env.storage)));
    await t.pump();
    await t.pump();
  }

  testWidgets('with no videos there is nothing to delete', (t) async {
    await show(t);
    expect(find.text('No videos saved'), findsOneWidget);
    expect(find.text('Delete all my videos'), findsNothing);
  });

  testWidgets('says how many videos and how much space they use', (t) async {
    await t.runAsync(() async {
      await env.add('Squat');
      await env.add('Row');
    });
    await show(t);
    expect(find.textContaining('2 videos · '), findsOneWidget);
    expect(find.textContaining('on this phone'), findsWidgets);
  });

  testWidgets('says where videos live and that they are not uploaded', (t) async {
    await t.runAsync(() async => env.add('Squat'));
    await show(t);
    expect(find.textContaining('only on this phone'), findsOneWidget);
    expect(find.textContaining('never uploaded'), findsOneWidget);
  });

  testWidgets('Delete all asks first, and Keep leaves everything', (t) async {
    await t.runAsync(() async => env.add('Squat'));
    await show(t);
    await t.tap(find.text('Delete all my videos'));
    await t.pumpAndSettle();
    expect(find.text('Delete all your videos?'), findsOneWidget);
    await t.tap(find.text('Keep'));
    await t.pumpAndSettle();
    expect(find.textContaining('1 video · '), findsOneWidget);
  });

  testWidgets('confirming deletes every video', (t) async {
    // A storage with no file IO: real IO needs real time, which lets the font
    // loader run and fail inside a widget test.
    final storage = _MemoryStorage([_video('a'), _video('b')]);
    await t.pumpWidget(MaterialApp(home: WorkoutVideosPage(storage: storage)));
    await t.pump();
    await t.pump();
    expect(find.textContaining('2 videos · '), findsOneWidget);

    await t.tap(find.text('Delete all my videos'));
    await t.pumpAndSettle();
    await t.tap(find.text('Delete all'));
    await t.pumpAndSettle();

    expect(storage.deleteAllCalls, 1);
    expect(find.text('No videos saved'), findsOneWidget);
    expect(find.text('All videos deleted'), findsOneWidget);
  });

  testWidgets('the empty state matches the design', (t) async {
    await show(t);
    expect(find.text('Workout videos'), findsOneWidget);
    expect(find.text('No videos saved'), findsOneWidget);
    expect(find.text('Film a set from any exercise page and it stays on this phone.'), findsOneWidget);
    expect(find.text('Deleting the app deletes your videos too.'), findsOneWidget);
    expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
    // Nothing saved means no count line and no grid.
    expect(find.textContaining(' on this phone'), findsNWidgets(1)); // the sentence above only
    expect(find.byType(VideoCatalogCard), findsNothing);
  });

  testWidgets('shows a card for every video, newest first', (t) async {
    await t.runAsync(() async {
      await env.add('Incline Dumbbell Press', at: DateTime(2026, 11, 18));
      await env.add('Barbell Back Squat', at: DateTime(2026, 11, 14));
      await env.add('Pull-up', at: DateTime(2026, 11, 11));
    });
    await show(t);

    expect(find.byType(VideoCatalogCard), findsNWidgets(3));
    expect(find.text('Incline Dumbbell Press'), findsOneWidget);
    expect(find.text('Barbell Back Squat'), findsOneWidget);
    expect(find.text('Pull-up'), findsOneWidget);
    // Date and length under the name.
    expect(find.text('Nov 18 · 0:42'), findsOneWidget);

    final order = t.widgetList<VideoCatalogCard>(find.byType(VideoCatalogCard)).map((c) => c.video.exerciseName);
    expect(order, ['Incline Dumbbell Press', 'Barbell Back Squat', 'Pull-up']);
  });

  testWidgets('only a video whose form was checked has the badge', (t) async {
    await t.runAsync(() async {
      await env.add('Squat', analysis: FormAnalysis(overallScore: 8, confidence: Confidence.high));
      await env.add('Row');
    });
    await show(t);
    expect(find.text('FORM CHECKED'), findsOneWidget);
  });

  testWidgets('the count line is singular for one video', (t) async {
    await t.runAsync(() async => env.add('Squat'));
    await show(t);
    expect(find.textContaining('1 video · '), findsOneWidget);
    expect(find.textContaining('1 videos'), findsNothing);
  });

  testWidgets('Delete all my videos keeps its own styling', (t) async {
    await t.runAsync(() async => env.add('Squat'));
    await show(t);

    final box = t.widget<Container>(find
        .ancestor(of: find.text('Delete all my videos'), matching: find.byType(Container))
        .first);
    final deco = box.decoration! as BoxDecoration;
    expect(deco.color, Colors.redAccent.withValues(alpha: 0.1));
    expect(deco.borderRadius, BorderRadius.circular(16));
    expect((deco.border! as Border).top.color, Colors.redAccent.withValues(alpha: 0.4));
    expect(box.padding, const EdgeInsets.symmetric(vertical: 15));

    final text = t.widget<Text>(find.text('Delete all my videos'));
    expect(text.style!.fontSize, 14);
    expect(text.style!.fontWeight, FontWeight.w600);
    expect(text.style!.color, Colors.redAccent);
  });

  testWidgets('the back button leaves the page', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => WorkoutVideosPage(storage: env.storage))),
          child: const Text('open'),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.byType(WorkoutVideosPage), findsOneWidget);

    await t.tap(find.bySemanticsLabel('Back'));
    await t.pumpAndSettle();
    expect(find.byType(WorkoutVideosPage), findsNothing);
  });

  group('analytics', () {
    late RecordingAnalytics rec;
    setUp(() {
      rec = RecordingAnalytics();
      Analytics.use(rec);
    });
    tearDown(() => Analytics.use(NoopAnalyticsService()));

    List<Map<String, Object?>?> named(String n) => [for (final e in rec.events) if (e.$1 == n) e.$2];

    testWidgets('opening the page reports how many videos and how many were checked', (t) async {
      final storage = _MemoryStorage([
        _video('a'),
        _video('b'),
        _video('c', analysed: true),
      ]);
      await t.pumpWidget(MaterialApp(home: WorkoutVideosPage(storage: storage)));
      await t.pump();
      await t.pump();

      expect(rec.screens, contains('workout_videos'));
      expect(named('workout_videos_opened'), [
        {'count': 3, 'analysed': 1}
      ]);
    });

    testWidgets('an empty page reports zero', (t) async {
      await show(t);
      expect(named('workout_videos_opened'), [
        {'count': 0, 'analysed': 0}
      ]);
    });

    testWidgets('deleting everything reports how many, only once it is confirmed', (t) async {
      final storage = _MemoryStorage([_video('a'), _video('b')]);
      await t.pumpWidget(MaterialApp(home: WorkoutVideosPage(storage: storage)));
      await t.pump();
      await t.pump();

      await t.tap(find.text('Delete all my videos'));
      await t.pumpAndSettle();
      await t.tap(find.text('Keep'));
      await t.pumpAndSettle();
      expect(named('workout_videos_deleted_all'), isEmpty);

      await t.tap(find.text('Delete all my videos'));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete all'));
      await t.pumpAndSettle();
      expect(named('workout_videos_deleted_all'), [
        {'count': 2}
      ]);
      // Deleting reloads the page; that is not opening it again.
      expect(named('workout_videos_opened'), hasLength(1));
    });

    testWidgets('no exercise name reaches analytics', (t) async {
      final storage = _MemoryStorage([_video('a')]);
      await t.pumpWidget(MaterialApp(home: WorkoutVideosPage(storage: storage)));
      await t.pump();
      await t.pump();
      final all = rec.events.map((e) => '${e.$1} ${e.$2}').join('\n');
      expect(all.contains('Squat'), isFalse);
    });
  });
}

ExerciseVideo _video(String id, {bool analysed = false}) => ExerciseVideo(
      id: id,
      recordedAt: DateTime(2026, 11, 1),
      durationMs: 30000,
      sizeBytes: 5 * 1024 * 1024,
      exerciseName: 'Squat',
      exerciseKey: 'squat',
      muscles: const [],
      filePath: 'x/$id.mp4',
      thumbnailPath: 'x/$id.jpg',
      analysis: analysed ? FormAnalysis(overallScore: 8, confidence: Confidence.high) : null,
    );

class _MemoryStorage extends ExerciseVideoStorage {
  List<ExerciseVideo> videos;
  int deleteAllCalls = 0;
  _MemoryStorage(this.videos);

  @override
  Future<List<ExerciseVideo>> all() async => videos;

  @override
  Future<void> deleteAll() async {
    deleteAllCalls++;
    videos = [];
    notifyListeners();
  }
}
