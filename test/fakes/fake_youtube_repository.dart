import 'package:fitness/domain/models/youtube_video.dart';
import 'package:fitness/domain/repositories/youtube_repository.dart';
import '../fixtures/fixtures.dart';

class FakeYouTubeRepository implements YouTubeRepository {
  List<YouTubeVideoEntity> searchResult = [Fixtures.video()];
  Exception? searchError;
  String? lastQuery;

  @override
  Future<dynamic> searchVideos(String query, {int maxResults = 5}) async {
    if (searchError != null) throw searchError!;
    lastQuery = query;
    return searchResult;
  }
}
