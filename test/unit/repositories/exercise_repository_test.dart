import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/data/repositories/exercise_repository_impl.dart';
import 'package:fitness/data/services/api/exercise_remote_service.dart';
import 'package:fitness/data/models/exercise/exercise_model.dart';

// ── Fake remote data source ───────────────────────────────────────────────────
// The ExerciseRemoteDataSource contract uses Model types (not entity types),
// so the fake must match those signatures.

class FakeExerciseRemoteDataSource implements ExerciseRemoteDataSource {
  List<ExerciseSearchResultModel> searchResult = [
    const ExerciseSearchResultModel(
      id: 'ex-001',
      name: 'Push Up',
      bodyPart: 'chest',
      equipment: 'bodyweight',
      gifUrl: 'https://example.com/pushup.gif',
    ),
  ];
  ExerciseModel detailResult = const ExerciseModel(
    id: 'ex-001',
    name: 'Push Up',
    primaryMuscles: ['chest'],
    secondaryMuscles: ['triceps'],
    instructions: ['Keep core tight'],
  );
  Exception? searchError;
  Exception? getByIdError;
  String? lastQuery;
  String? lastId;

  @override
  Future<List<ExerciseSearchResultModel>> searchExercises(String query) async {
    if (searchError != null) throw searchError!;
    lastQuery = query;
    return searchResult;
  }

  @override
  Future<ExerciseModel> getExerciseById(String exerciseId) async {
    if (getByIdError != null) throw getByIdError!;
    lastId = exerciseId;
    return detailResult;
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeExerciseRemoteDataSource dataSource;
  late ExerciseRepositoryImpl repo;

  setUp(() {
    dataSource = FakeExerciseRemoteDataSource();
    repo = ExerciseRepositoryImpl(remoteDataSource: dataSource);
  });

  group('searchExercises', () {
    test('returns results from data source', () async {
      final result = await repo.searchExercises('push up');
      expect(result.length, 1);
      expect(result.first.name, 'Push Up');
      expect(dataSource.lastQuery, 'push up');
    });

    test('returns empty list when data source returns empty', () async {
      dataSource.searchResult = [];
      final result = await repo.searchExercises('nothing');
      expect(result, isEmpty);
    });

    test('propagates exception from data source', () async {
      dataSource.searchError = Exception('Network error');
      expect(() => repo.searchExercises('push up'), throwsException);
    });
  });

  group('getExerciseById', () {
    test('returns exercise from data source', () async {
      final result = await repo.getExerciseById('ex-001');
      expect(result.id, 'ex-001');
      expect(dataSource.lastId, 'ex-001');
    });

    test('propagates exception when exercise not found', () async {
      dataSource.getByIdError = Exception('Not found');
      expect(() => repo.getExerciseById('bad-id'), throwsException);
    });
  });
}
