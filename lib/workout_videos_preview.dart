// Design-review entry point for the Workout videos screen. Not part of the app:
// it shows the screen with sample videos and nothing behind it.
//
//   flutter run -t lib/workout_videos_preview.dart -d <device>
//
// On web, open a state with ?screen=populated|empty|loading
import 'dart:async';
import 'dart:io';

import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/profile/views/workout_videos_page.dart';
import 'package:flutter/material.dart';

void main() => runApp(const _App());

ExerciseVideo _video(String id, String name, DateTime at, {int seconds = 24, bool checked = false}) => ExerciseVideo(
      id: id,
      recordedAt: at,
      durationMs: seconds * 1000,
      sizeBytes: 15 * 1024 * 1024,
      exerciseName: name,
      exerciseKey: name.toLowerCase(),
      muscles: const [],
      filePath: 'x/$id.mp4',
      thumbnailPath: 'x/$id.jpg',
      analysis: checked ? FormAnalysis(overallScore: 8, confidence: Confidence.high) : null,
    );

/// Videos held in memory. With no files, every card shows its placeholder
/// picture, which is also what the app shows for a missing thumbnail.
class _PreviewStorage extends ExerciseVideoStorage {
  final List<ExerciseVideo> videos;
  final bool never;
  _PreviewStorage(this.videos, {this.never = false});

  @override
  Future<List<ExerciseVideo>> all() => never ? Completer<List<ExerciseVideo>>().future : Future.value(videos);

  @override
  Future<File> thumbnailFile(ExerciseVideo v) => Future.error(StateError('preview has no files'));
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    final screen = Uri.base.queryParameters['screen'] ?? 'populated';
    final storage = switch (screen) {
      'empty' => _PreviewStorage(const []),
      'loading' => _PreviewStorage(const [], never: true),
      _ => _PreviewStorage([
          _video('a', 'Incline Dumbbell Press', DateTime(2025, 11, 18), seconds: 24, checked: true),
          _video('b', 'Barbell Back Squat', DateTime(2025, 11, 14), seconds: 31, checked: true),
          _video('c', 'Pull-up', DateTime(2025, 11, 11), seconds: 18),
          _video('d', 'Cable Fly', DateTime(2025, 11, 8), seconds: 31),
          _video('e', 'Romanian Deadlift', DateTime(2025, 10, 30), seconds: 27, checked: true),
          _video('f', 'Single-arm Dumbbell Lateral Raise', DateTime(2025, 10, 22), seconds: 15),
        ]),
    };

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: kBodyBg),
      builder: (context, child) => ColoredBox(
        color: kBodyBg,
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 390), child: child)),
      ),
      home: WorkoutVideosPage(storage: storage),
    );
  }
}
