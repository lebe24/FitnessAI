import 'package:fitness/app/api/domain/entities/youtube_video_entity.dart';

/// Model representing a YouTube video from YouTube Data API
class YouTubeVideoModel extends YouTubeVideoEntity {
  const YouTubeVideoModel({
    required super.videoId,
    required super.title,
    required super.description,
    required super.thumbnailUrl,
    required super.channelTitle,
    required super.publishedAt,
  });

  factory YouTubeVideoModel.fromJson(Map<String, dynamic> json) {
    // Handle RapidAPI YouTube format (may differ from standard YouTube API)
    // Try to extract videoId from different possible locations
    String? videoId;
    if (json.containsKey('videoId')) {
      videoId = json['videoId'] as String?;
    } else if (json.containsKey('id')) {
      final id = json['id'];
      if (id is String) {
        videoId = id;
      } else if (id is Map) {
        videoId = id['videoId'] as String? ?? id['id'] as String?;
      }
    }
    
    // Handle snippet or direct fields (RapidAPI format)
    final snippet = json['snippet'] as Map<String, dynamic>?;
    final title = snippet?['title'] as String? ?? json['title'] as String? ?? '';
    final description = snippet?['description'] as String? ?? json['description'] as String? ?? '';
    final channelTitle = snippet?['channelTitle'] as String? ?? json['channelTitle'] as String? ?? '';
    
    // Handle thumbnails
    String thumbnailUrl = '';
    if (snippet != null && snippet.containsKey('thumbnails')) {
      final thumbnails = snippet['thumbnails'] as Map<String, dynamic>?;
      final highThumbnail = thumbnails?['high'] as Map<String, dynamic>?;
      final mediumThumbnail = thumbnails?['medium'] as Map<String, dynamic>?;
      final defaultThumbnail = thumbnails?['default'] as Map<String, dynamic>?;
      thumbnailUrl = highThumbnail?['url'] as String? ??
          mediumThumbnail?['url'] as String? ??
          defaultThumbnail?['url'] as String? ??
          '';
    } else if (json.containsKey('thumbnail')) {
      final thumbnail = json['thumbnail'];
      if (thumbnail is String) {
        thumbnailUrl = thumbnail;
      } else if (thumbnail is List && thumbnail.isNotEmpty) {
        thumbnailUrl = thumbnail[0] as String? ?? '';
      } else if (thumbnail is Map) {
        thumbnailUrl = thumbnail['url'] as String? ?? thumbnail['src'] as String? ?? '';
      }
    }
    
    // Handle published date
    DateTime publishedAt = DateTime.now();
    final publishedAtStr = snippet?['publishedAt'] as String? ?? json['publishedAt'] as String?;
    if (publishedAtStr != null) {
      try {
        publishedAt = DateTime.parse(publishedAtStr);
      } catch (_) {
        publishedAt = DateTime.now();
      }
    }

    return YouTubeVideoModel(
      videoId: videoId ?? '',
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      channelTitle: channelTitle,
      publishedAt: publishedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': {'videoId': videoId},
      'snippet': {
        'title': title,
        'description': description,
        'thumbnails': {
          'default': {'url': thumbnailUrl},
          'medium': {'url': thumbnailUrl},
          'high': {'url': thumbnailUrl},
        },
        'channelTitle': channelTitle,
        'publishedAt': publishedAt.toIso8601String(),
      },
    };
  }
}

