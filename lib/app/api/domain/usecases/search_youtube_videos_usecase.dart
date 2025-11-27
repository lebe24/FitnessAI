import 'package:fitness/app/api/domain/entities/youtube_video_entity.dart';
import 'package:fitness/app/api/domain/repositories/youtube_repository.dart';

/// Use case for searching YouTube videos
class SearchYouTubeVideosUsecase {
  final YouTubeRepository repository;

  SearchYouTubeVideosUsecase(this.repository);

  Future<dynamic> call(String query, {int maxResults = 5}) async {
    return await repository.searchVideos(query, maxResults: maxResults);
  }
}

