import 'package:equatable/equatable.dart';

/// Entity representing a YouTube video from YouTube Data API
class YouTubeVideoEntity extends Equatable {
  final String videoId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final DateTime publishedAt;

  const YouTubeVideoEntity({
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.publishedAt,
  });

  @override
  List<Object?> get props => [
        videoId,
        title,
        description,
        thumbnailUrl,
        channelTitle,
        publishedAt,
      ];
}

