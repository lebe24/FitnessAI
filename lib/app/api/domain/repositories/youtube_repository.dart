import 'package:fitness/app/api/domain/entities/youtube_video_entity.dart';

/// Repository interface for YouTube Data API
abstract class YouTubeRepository {
  /// Search for workout videos
  /// [query] is the search term (usually exercise name + "workout")
  /// [maxResults] is the maximum number of results to return (default: 5)
  /// Returns a list of YouTube videos
  Future<dynamic> searchVideos(String query, {int maxResults = 5});
}

