import 'package:fitness/domain/models/youtube_video.dart';
import 'package:fitness/domain/repositories/youtube_repository.dart';

/// Use case for searching YouTube videos
class SearchYouTubeVideosUsecase {
  final YouTubeRepository repository;

  SearchYouTubeVideosUsecase(this.repository);

  Future<dynamic> call(String query, {int maxResults = 5}) async {
    return await repository.searchVideos(query, maxResults: maxResults);
  }
}

