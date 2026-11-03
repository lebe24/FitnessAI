import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/ui/features/profile/views/workout_videos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(find.text('2 videos'), findsOneWidget);
    expect(find.textContaining('on this phone'), findsWidgets);
  });

  testWidgets('says where videos live and that they are not uploaded', (t) async {
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
    expect(find.text('1 video'), findsOneWidget);
  });

  testWidgets('confirming deletes every video', (t) async {
    // A storage with no file IO: real IO needs real time, which lets the font
    // loader run and fail inside a widget test.
    final storage = _MemoryStorage([_video('a'), _video('b')]);
    await t.pumpWidget(MaterialApp(home: WorkoutVideosPage(storage: storage)));
    await t.pump();
    await t.pump();
    expect(find.text('2 videos'), findsOneWidget);

    await t.tap(find.text('Delete all my videos'));
    await t.pumpAndSettle();
    await t.tap(find.text('Delete all'));
    await t.pumpAndSettle();

    expect(storage.deleteAllCalls, 1);
    expect(find.text('No videos saved'), findsOneWidget);
    expect(find.text('All videos deleted'), findsOneWidget);
  });
}

ExerciseVideo _video(String id) => ExerciseVideo(
      id: id,
      recordedAt: DateTime(2026, 11, 1),
      durationMs: 30000,
      sizeBytes: 5 * 1024 * 1024,
      exerciseName: 'Squat',
      exerciseKey: 'squat',
      muscles: const [],
      filePath: 'x/$id.mp4',
      thumbnailPath: 'x/$id.jpg',
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
