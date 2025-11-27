import 'package:fitness/app/api/data/datasources/youtube_remote_datasource.dart';
import 'package:fitness/app/api/data/models/youtube_video_model.dart';
import 'package:fitness/app/api/domain/entities/youtube_video_entity.dart';
import 'package:fitness/app/api/domain/repositories/youtube_repository.dart';

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

