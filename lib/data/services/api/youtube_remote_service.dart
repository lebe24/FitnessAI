import 'package:dio/dio.dart';
import 'package:fitness/ui/core/constants/constant.dart';

/// Data source interface for YouTube via RapidAPI
abstract class YouTubeRemoteDataSource {
  /// Search for videos via RapidAPI
  Future<dynamic> searchVideos(String query, {int maxResults = 5});
}

class YouTubeRemoteDataSourceImpl implements YouTubeRemoteDataSource {
  late final Dio _dio;

  YouTubeRemoteDataSourceImpl() {
    _dio = Dio(BaseOptions(
      baseUrl: Constant.youtubeRapidApiBaseUrl,  
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        if (Constant.youtubeRapidApiKey!.isNotEmpty) 'x-rapidapi-key': Constant.youtubeRapidApiKey,
        'x-rapidapi-host': Constant.youtubeRapidApiHost,
      },
    ));
  }

  @override
  Future<dynamic> searchVideos(
    String query,
    {int maxResults = 5}
  ) async {
    try {
      final apiKey = Constant.youtubeRapidApiKey;

      if (apiKey!.isEmpty) {
        throw Exception('RapidAPI YouTube key is missing');
      }

      final response = await _dio.get(
        '/search/',
        queryParameters: {
          'q': '$query Workout exercise tutorial',
          'hl': 'en',
          'gl': 'US',
          'maxResults': maxResults,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data ;
        
        // RapidAPI YouTube response format may vary
        // Try to find items in different possible locations
        // List<dynamic> items = [];
        
        // if (data != null) {
        //   if (data.containsKey('contents')) {
        //     final contents = data['contents'];
        //     if (contents is List) {
        //       items = contents;
        //     } else if (contents is Map && contents.containsKey('items')) {
        //       items = contents['items'] as List<dynamic>? ?? [];
        //     }
        //   } else if (data.containsKey('items')) {
        //     items = data['items'] as List<dynamic>? ?? [];
        //   } else if (data.containsKey('data')) {
        //     final dataList = data['data'];
        //     if (dataList is List) {
        //       items = dataList;
        //     }
        //   }
        // }
        
        // Map items to YouTubeVideoModel
        return data;
            
      } else {
        throw Exception('Failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw Exception('RapidAPI quota exceeded');
      }
      throw Exception('RapidAPI request failed: ${e.message}');
    } catch (e) {
      throw Exception('Unknown YouTube API error: $e');
    }
  }
}
