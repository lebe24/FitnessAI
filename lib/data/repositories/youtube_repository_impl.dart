import 'package:fitness/data/services/api/youtube_remote_service.dart';
import 'package:fitness/domain/repositories/youtube_repository.dart';

/// Implementation of YouTubeRepository
class YouTubeRepositoryImpl implements YouTubeRepository {
  final YouTubeRemoteDataSource remoteDataSource;

  YouTubeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<dynamic> searchVideos(String query, {int maxResults = 5}) async {
    final videos = await remoteDataSource.searchVideos(query, maxResults: maxResults);
    return videos;
  }
}

