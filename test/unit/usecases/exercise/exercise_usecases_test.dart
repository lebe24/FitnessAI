import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/domain/use_cases/exercise/search_exercises_usecase.dart';
import 'package:fitness/domain/use_cases/exercise/get_exercise_by_id_usecase.dart';
import 'package:fitness/domain/use_cases/exercise/search_youtube_videos_usecase.dart';
import '../../../fakes/fake_exercise_repository.dart';
import '../../../fakes/fake_youtube_repository.dart';
import '../../../fixtures/fixtures.dart';

void main() {
  // ── SearchExercisesUsecase ─────────────────────────────────────────────────

  group('SearchExercisesUsecase', () {
    late FakeExerciseRepository repo;
    late SearchExercisesUsecase usecase;

    setUp(() {
      repo = FakeExerciseRepository();
      usecase = SearchExercisesUsecase(repo);
    });

    test('returns results and forwards query to repository', () async {
      final result = await usecase('push up');
      expect(result.length, 1);
      expect(result.first.name, 'Push Up');
      expect(repo.lastSearchQuery, 'push up');
    });

    test('returns empty list when repository returns empty', () async {
      repo.searchResult = [];
      final result = await usecase('nothing');
      expect(result, isEmpty);
    });

    test('propagates exception from repository', () async {
      repo.searchError = Exception('Search failed');
      expect(() => usecase('push up'), throwsException);
    });
  });

  // ── GetExerciseByIdUsecase ─────────────────────────────────────────────────

  group('GetExerciseByIdUsecase', () {
    late FakeExerciseRepository repo;
    late GetExerciseByIdUsecase usecase;

    setUp(() {
      repo = FakeExerciseRepository();
      usecase = GetExerciseByIdUsecase(repo);
    });

    test('returns exercise for given id', () async {
      final result = await usecase('ex-001');
      expect(result.id, 'ex-001');
      expect(result.name, 'Push Up');
      expect(repo.lastGetByIdArg, 'ex-001');
    });

    test('propagates exception when exercise not found', () async {
      repo.getByIdError = Exception('Not found');
      expect(() => usecase('bad-id'), throwsException);
    });
  });

  // ── SearchYouTubeVideosUsecase ─────────────────────────────────────────────

  group('SearchYouTubeVideosUsecase', () {
    late FakeYouTubeRepository repo;
    late SearchYouTubeVideosUsecase usecase;

    setUp(() {
      repo = FakeYouTubeRepository();
      usecase = SearchYouTubeVideosUsecase(repo);
    });

    test('returns videos and forwards query', () async {
      final result = await usecase('push up tutorial');
      expect(result, isNotEmpty);
      expect(repo.lastQuery, 'push up tutorial');
    });

    test('returns empty list when no videos found', () async {
      repo.searchResult = [];
      final result = await usecase('very obscure query');
      expect(result, isEmpty);
    });
  });
}
