/// A playable video out of a RapidAPI youtube138 search response.
class VideoSummary {
  final String id;
  final String title;
  final String thumbnailUrl;

  const VideoSummary({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
  });

  /// Every playable video in a search response, in the order returned.
  ///
  /// The response mixes videos with channels and playlists, which carry no
  /// `video` object. Those are dropped here rather than rendered as cards that
  /// do nothing when tapped.
  static List<VideoSummary> listFrom(dynamic response) {
    if (response is! Map) return const [];
    final contents = response['contents'];
    if (contents is! List) return const [];

    final out = <VideoSummary>[];
    for (final entry in contents) {
      if (entry is! Map) continue;
      final video = entry['video'];
      if (video is! Map) continue;
      final id = video['videoId'];
      if (id is! String || id.isEmpty) continue;

      var thumbnail = '';
      final thumbs = video['thumbnails'];
      if (thumbs is List && thumbs.isNotEmpty) {
        // The second thumbnail is the larger one when there is more than one.
        final pick = thumbs.length > 1 ? thumbs[1] : thumbs[0];
        if (pick is Map && pick['url'] is String) thumbnail = pick['url'];
      }

      final title = video['title'];
      out.add(VideoSummary(
        id: id,
        title: title is String ? title : '',
        thumbnailUrl: thumbnail,
      ));
    }
    return out;
  }
}
