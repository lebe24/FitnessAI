import 'dart:io';

import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/data/services/video/video_import_service.dart';
import 'package:fitness/data/services/video/video_tools.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import '../../support/synthetic_clip.dart';

class _Picker implements VideoPicker {
  String? path;
  Object? error;
  VideoSource? asked;
  @override
  Future<String?> pick(VideoSource source) async {
    asked = source;
    if (error != null) throw error!;
    return path;
  }
}

void main() {
  late Directory docs, tmp;
  late ExerciseVideoStorage storage;
  late FakeVideoTools tools;
  late _Picker picker;
  late VideoImportService service;
  late File source;

  Future<void> build({VideoInfo? info}) async {
    tools = FakeVideoTools(
        infoResult: info ?? const VideoInfo(durationMs: 45000, width: 720, height: 1280));
    picker = _Picker();
    service = VideoImportService(
      tools: tools,
      storage: storage,
      picker: picker,
      tempDirectory: () async => tmp,
      newId: () => 'clip1',
      supported: () => true,
    );
  }

  setUp(() async {
    docs = Directory.systemTemp.createTempSync('imp_docs');
    tmp = Directory.systemTemp.createTempSync('imp_tmp');
    Hive.init(Directory.systemTemp.createTempSync('imp_hive').path);
    await Hive.openBox<Map>(ExerciseVideoStorage.boxName);
    storage = ExerciseVideoStorage(documents: () async => docs);
    source = File(p.join(tmp.path, 'picked.mov'))..writeAsBytesSync(List.filled(500, 3));
    await build();
  });

  tearDown(() async {
    await Hive.close();
    for (final d in [docs, tmp]) {
      if (d.existsSync()) d.deleteSync(recursive: true);
    }
  });

  group('picking', () {
    test('returns the clip and how long it is', () async {
      picker.path = source.path;
      final picked = await service.pick(VideoSource.record);
      expect(picker.asked, VideoSource.record);
      expect(picked!.info.durationMs, 45000);
      expect(picked.needsTrim, isFalse);
    });

    test('is null when the user backs out', () async {
      picker.path = null;
      expect(await service.pick(VideoSource.library), isNull);
    });

    test('a clip over 60 seconds needs trimming', () async {
      await build(info: const VideoInfo(durationMs: 148000, width: 1080, height: 1920));
      picker.path = source.path;
      expect((await service.pick(VideoSource.library))!.needsTrim, isTrue);
    });

    test('refuses politely when the phone is nearly full, before asking for a clip', () async {
      tools.free = 50 * 1024 * 1024;
      picker.path = source.path;
      await expectLater(
        service.pick(VideoSource.record),
        throwsA(isA<VideoImportException>()
            .having((e) => e.problem, 'problem', VideoImportProblem.lowStorage)),
      );
      expect(picker.asked, isNull, reason: 'no point opening the camera');
    });

    test('an unknown amount of free space does not block', () async {
      tools.free = null;
      picker.path = source.path;
      expect(await service.pick(VideoSource.record), isNotNull);
    });

    test('an unreadable file is reported as such', () async {
      picker.path = source.path;
      tools.infoError = const VideoToolsException('no_video', 'x');
      await expectLater(
        service.pick(VideoSource.library),
        throwsA(isA<VideoImportException>()
            .having((e) => e.problem, 'problem', VideoImportProblem.unreadable)),
      );
    });

    test('a refused permission passes through', () async {
      picker.error = const VideoImportException(VideoImportProblem.permission, 'denied');
      await expectLater(
        service.pick(VideoSource.record),
        throwsA(isA<VideoImportException>()
            .having((e) => e.problem, 'problem', VideoImportProblem.permission)),
      );
    });

    test('says so on a platform that is not supported yet', () async {
      final unsupported = VideoImportService(
          tools: tools, storage: storage, picker: picker, tempDirectory: () async => tmp, supported: () => false);
      await expectLater(
        unsupported.pick(VideoSource.record),
        throwsA(isA<VideoImportException>()
            .having((e) => e.problem, 'problem', VideoImportProblem.unsupported)),
      );
    });
  });

  group('the kept window', () {
    PickedVideo clip(int ms) => PickedVideo(
        '/x', VideoInfo(durationMs: ms, width: 1, height: 2), VideoSource.library);

    test('a short clip is kept whole', () {
      expect(VideoImportService.windowFor(clip(45000), 0), (0, 45000));
    });

    test('a long clip keeps 60 s from the chosen start', () {
      expect(VideoImportService.windowFor(clip(148000), 30000), (30000, 90000));
    });

    test('the window never runs past the end, and always keeps at least a second', () {
      expect(VideoImportService.windowFor(clip(148000), 90000), (90000, 148000));
      expect(VideoImportService.windowFor(clip(148000), 140000), (140000, 148000));
      expect(VideoImportService.windowFor(clip(148000), 148000), (147000, 148000));
    });

    test('a negative start is zero', () {
      expect(VideoImportService.windowFor(clip(148000), -5), (0, 60000));
    });
  });

  group('saving', () {
    test('compresses, makes a thumbnail, and stores the clip', () async {
      picker.path = source.path;
      final picked = (await service.pick(VideoSource.record))!;
      final progress = <double>[];
      final saved = await service.save(picked,
          exerciseName: 'Pull-Ups',
          muscles: const ['upper-back', 'biceps'],
          dayLabel: 'Tuesday',
          onProgress: progress.add);

      expect(saved.id, 'clip1');
      expect(saved.durationMs, 45000);
      expect(saved.muscles, ['upper-back', 'biceps']);
      expect(tools.lastExport, (start: 0, end: 45000));
      expect(progress, [0.5, 1.0]);
      expect(File(p.join(docs.path, saved.filePath)).existsSync(), isTrue);
      expect(File(p.join(docs.path, saved.thumbnailPath)).lengthSync(), greaterThan(0));
      expect((await storage.forExercise('pull up')).single.id, 'clip1');
    });

    test('a long clip is trimmed to the chosen minute', () async {
      await build(info: const VideoInfo(durationMs: 148000, width: 1080, height: 1920));
      picker.path = source.path;
      final picked = (await service.pick(VideoSource.library))!;
      final saved = await service.save(picked,
          exerciseName: 'Deadlift', muscles: const [], startMs: 20000);
      expect(tools.lastExport, (start: 20000, end: 80000));
      expect(saved.durationMs, 60000);
    });

    test('a start offset is ignored for a clip that fits', () async {
      picker.path = source.path;
      final picked = (await service.pick(VideoSource.record))!;
      await service.save(picked, exerciseName: 'x', muscles: const [], startMs: 20000);
      expect(tools.lastExport, (start: 0, end: 45000));
    });

    test('the temporary files are cleaned up, including the picker\'s copy', () async {
      picker.path = source.path;
      final picked = (await service.pick(VideoSource.library))!;
      await service.save(picked, exerciseName: 'x', muscles: const []);
      expect(source.existsSync(), isFalse, reason: 'the large library copy is removed');
      expect(File(p.join(tmp.path, 'befit_clip1.mp4')).existsSync(), isFalse);
      expect(File(p.join(tmp.path, 'befit_clip1.jpg')).existsSync(), isFalse);
    });

    test('a failed export saves nothing and cleans up', () async {
      picker.path = source.path;
      final picked = (await service.pick(VideoSource.record))!;
      tools.exportError = const VideoToolsException('export', 'bad codec');
      await expectLater(
        service.save(picked, exerciseName: 'x', muscles: const []),
        throwsA(isA<VideoImportException>()
            .having((e) => e.problem, 'problem', VideoImportProblem.failed)),
      );
      expect(await storage.all(), isEmpty);
      expect(tmp.listSync().whereType<File>().map((f) => p.basename(f.path)),
          isNot(contains('befit_clip1.mp4')));
    });

    test('a cancelled export is reported as cancelled and saves nothing', () async {
      picker.path = source.path;
      final picked = (await service.pick(VideoSource.record))!;
      tools.exportError = const VideoExportCancelled();
      await expectLater(
        service.save(picked, exerciseName: 'x', muscles: const []),
        throwsA(isA<VideoImportException>()
            .having((e) => e.problem, 'problem', VideoImportProblem.cancelled)),
      );
      expect(await storage.all(), isEmpty);
    });

    test('cancel stops the platform export', () async {
      await service.cancel();
      expect(tools.cancelCalls, 1);
    });

    test('a failed thumbnail does not lose the clip', () async {
      picker.path = source.path;
      final picked = (await service.pick(VideoSource.record))!;
      tools.thumbnailError = const VideoToolsException('encode', 'x');
      final saved = await service.save(picked, exerciseName: 'x', muscles: const []);
      expect(File(p.join(docs.path, saved.filePath)).existsSync(), isTrue);
      expect(await storage.byId('clip1'), isNotNull);
    });
  });
}
