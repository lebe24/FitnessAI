import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/api/domain/usecases/search_youtube_videos_usecase.dart';
import 'package:fitness/app/api/domain/repositories/youtube_repository.dart';
import 'package:fitness/app/api/domain/entities/youtube_video_entity.dart';

class MockYouTubeRepository extends Mock implements YouTubeRepository {}

void main() {
  late SearchYouTubeVideosUsecase usecase;
  late MockYouTubeRepository mockRepository;

  setUp(() {
    mockRepository = MockYouTubeRepository();
    usecase = SearchYouTubeVideosUsecase(mockRepository);
  });

  test('should search YouTube videos and return results', () async {
    // arrange
    const query = 'push up tutorial';
    final testVideos = [
      YouTubeVideoEntity(
        videoId: 'abc123',
        title: 'Push Up Tutorial',
        description: 'Learn how to do push ups',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        channelTitle: 'Fitness Channel',
        publishedAt: DateTime.now(),
      ),
    ];
    when(mockRepository.searchVideos(query))
        .thenAnswer((_) async => testVideos);

    // act
    final result = await usecase(query);

    // assert
    expect(result, equals(testVideos));
    expect(result.length, equals(1));
    verify(mockRepository.searchVideos(query)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return empty list when no videos found', () async {
    // arrange
    const query = 'nonexistent video';
    when(mockRepository.searchVideos(query))
        .thenAnswer((_) async => []);

    // act
    final result = await usecase(query);

    // assert
    expect(result, isEmpty);
    verify(mockRepository.searchVideos(query)).called(1);
  });
}

