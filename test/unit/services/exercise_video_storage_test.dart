import 'dart:io';

import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory docs;
  late Directory scratch;
  late ExerciseVideoStorage storage;
  var n = 0;

  File temp(String name, {int bytes = 10}) {
    final f = File(p.join(scratch.path, '${n++}_$name'));
    f.writeAsBytesSync(List.filled(bytes, 7));
    return f;
  }

  Future<ExerciseVideo> add(
    String id,
    String exercise, {
    List<String> muscles = const [],
    DateTime? at,
    int bytes = 10,
  }) =>
      storage.save(
        id: id,
        video: temp('$id.mp4', bytes: bytes),
        thumbnail: temp('$id.jpg'),
        durationMs: 30000,
        exerciseName: exercise,
        muscles: muscles,
        recordedAt: at ?? DateTime(2026, 11, 1),
      );

  setUp(() async {
    docs = Directory.systemTemp.createTempSync('videos_docs');
    scratch = Directory.systemTemp.createTempSync('videos_scratch');
    Hive.init(Directory.systemTemp.createTempSync('videos_hive').path);
    await Hive.openBox<Map>(ExerciseVideoStorage.boxName);
    storage = ExerciseVideoStorage(documents: () async => docs);
  });

  tearDown(() async {
    await Hive.close();
    for (final d in [docs, scratch]) {
      if (d.existsSync()) d.deleteSync(recursive: true);
    }
  });

  File fileOf(String rel) => File(p.join(docs.path, rel));

  group('saving', () {
    test('moves the files into place and records the entry', () async {
      final video = temp('clip.mp4', bytes: 123);
      final thumb = temp('clip.jpg');
      final saved = await storage.save(
        id: 'v1',
        video: video,
        thumbnail: thumb,
        durationMs: 45000,
        exerciseName: 'Deadlift',
        muscles: const ['hamstring', 'lower-back'],
        dayLabel: 'Monday',
      );
      expect(saved.filePath, p.join('exercise_videos', 'v1.mp4'));
      expect(saved.sizeBytes, 123);
      expect(fileOf(saved.filePath).existsSync(), isTrue);
      expect(fileOf(saved.thumbnailPath).existsSync(), isTrue);
      expect(video.existsSync(), isFalse, reason: 'moved, not copied');
      expect(thumb.existsSync(), isFalse);
      expect((await storage.byId('v1'))!.muscles, ['hamstring', 'lower-back']);
    });

    test('tells listeners', () async {
      var calls = 0;
      storage.addListener(() => calls++);
      await add('v1', 'Squat');
      expect(calls, 1);
    });
  });

  group('listing', () {
    test('newest first', () async {
      await add('old', 'Squat', at: DateTime(2026, 10, 1));
      await add('new', 'Squat', at: DateTime(2026, 11, 1));
      await add('mid', 'Squat', at: DateTime(2026, 10, 15));
      expect((await storage.all()).map((v) => v.id), ['new', 'mid', 'old']);
    });

    test('by exercise, matching spelling variants', () async {
      await add('a', 'Pull-Ups');
      await add('b', 'pull up');
      await add('c', 'Bench Press');
      expect((await storage.forExercise('Pull ups')).map((v) => v.id).toSet(), {'a', 'b'});
      expect(await storage.forExercise('Row'), isEmpty);
      expect(await storage.forExercise(''), isEmpty);
    });

    test('by muscle, using the muscles saved with each video', () async {
      await add('a', 'Pull-Ups', muscles: ['upper-back', 'biceps']);
      await add('b', 'Curl', muscles: ['biceps']);
      await add('c', 'Squat', muscles: ['quadriceps']);
      expect((await storage.forMuscle('biceps')).map((v) => v.id).toSet(), {'a', 'b'});
      expect((await storage.forMuscle('upper-back')).map((v) => v.id), ['a']);
      expect(await storage.forMuscle('calves'), isEmpty);
      expect(await storage.countsByMuscle(), {'upper-back': 1, 'biceps': 2, 'quadriceps': 1});
    });

    test('total size adds up', () async {
      await add('a', 'Squat', bytes: 100);
      await add('b', 'Squat', bytes: 250);
      expect(await storage.totalBytes(), 350);
    });

    test('a damaged entry does not hide the others', () async {
      await add('good', 'Squat');
      await Hive.box<Map>(ExerciseVideoStorage.boxName).put('bad', {'junk': true});
      expect((await storage.all()).map((v) => v.id), ['good']);
    });
  });

  group('analysis', () {
    test('is stored with the video and survives reading it back', () async {
      await add('a', 'Deadlift');
      final updated = await storage.setAnalysis(
          'a', const FormAnalysis(overallScore: 7, summary: 'ok'), model: 'luna');
      expect(updated!.isAnalysed, isTrue);
      final again = (await storage.byId('a'))!;
      expect(again.analysis!.overallScore, 7);
      expect(again.analysisModel, 'luna');
      expect(again.analysedAt, isNotNull);
    });

    test('is dropped quietly if the video was deleted while analysing', () async {
      await add('a', 'Deadlift');
      await storage.delete('a');
      expect(await storage.setAnalysis('a', const FormAnalysis()), isNull);
      expect(await storage.byId('a'), isNull, reason: 'must not resurrect the entry');
    });
  });

  group('deleting', () {
    test('removes the entry, the video and the thumbnail together', () async {
      final v = await add('a', 'Squat');
      await storage.delete('a');
      expect(await storage.byId('a'), isNull);
      expect(fileOf(v.filePath).existsSync(), isFalse);
      expect(fileOf(v.thumbnailPath).existsSync(), isFalse);
    });

    test('leaves the other videos alone', () async {
      await add('a', 'Squat');
      final b = await add('b', 'Squat');
      await storage.delete('a');
      expect((await storage.all()).map((v) => v.id), ['b']);
      expect(fileOf(b.filePath).existsSync(), isTrue);
    });

    test('deleting something that is not there is harmless', () async {
      await storage.delete('nope');
    });

    test('delete all clears every file and entry', () async {
      final a = await add('a', 'Squat');
      final b = await add('b', 'Row');
      await storage.deleteAll();
      expect(await storage.all(), isEmpty);
      expect(fileOf(a.filePath).existsSync(), isFalse);
      expect(fileOf(b.filePath).existsSync(), isFalse);
      // And it is usable afterwards.
      await add('c', 'Squat');
      expect((await storage.all()).single.id, 'c');
    });
  });

  group('startup clean-up', () {
    test('removes a file that has no entry', () async {
      await add('a', 'Squat');
      final stray = File(p.join(docs.path, 'exercise_videos', 'stray.mp4'))
        ..writeAsBytesSync([1, 2, 3]);
      final report = await storage.cleanUp();
      expect(report.orphanFiles, 1);
      expect(stray.existsSync(), isFalse);
      expect((await storage.all()).single.id, 'a');
    });

    test('removes an entry whose video file is gone', () async {
      final v = await add('a', 'Squat');
      fileOf(v.filePath).deleteSync();
      final report = await storage.cleanUp();
      expect(report.brokenEntries, 1);
      expect(await storage.all(), isEmpty);
      expect(fileOf(v.thumbnailPath).existsSync(), isFalse, reason: 'its thumbnail goes too');
    });

    test('keeps an entry that only lost its thumbnail: the video still plays', () async {
      final v = await add('a', 'Squat');
      fileOf(v.thumbnailPath).deleteSync();
      final report = await storage.cleanUp();
      expect(report.isEmpty, isTrue);
      expect((await storage.all()).single.id, 'a');
    });

    test('does nothing when everything matches', () async {
      await add('a', 'Squat');
      await add('b', 'Row');
      var calls = 0;
      storage.addListener(() => calls++);
      expect((await storage.cleanUp()).isEmpty, isTrue);
      expect(calls, 0);
      expect(await storage.all(), hasLength(2));
    });

    test('removes a damaged entry', () async {
      await Hive.box<Map>(ExerciseVideoStorage.boxName).put('bad', {'junk': true});
      expect((await storage.cleanUp()).brokenEntries, 1);
    });
  });
}
