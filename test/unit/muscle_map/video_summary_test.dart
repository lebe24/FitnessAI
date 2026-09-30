import 'package:fitness/data/models/youtube/video_summary.dart';
import 'package:fitness/domain/models/muscle.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shaped like a RapidAPI youtube138 search response, which is what the
/// existing YouTube data source returns untouched.
void main() {
  test('keeps videos and drops channels and playlists', () {
    final list = VideoSummary.listFrom({
      'contents': [
        {
          'type': 'video',
          'video': {
            'videoId': 'abc123',
            'title': 'Best bicep workout',
            'thumbnails': [
              {'url': 'https://i.ytimg.com/small.jpg'},
              {'url': 'https://i.ytimg.com/large.jpg'},
            ],
          },
        },
        {'type': 'channel', 'channel': {'channelId': 'UCx'}},
        {'type': 'playlist', 'playlist': {'playlistId': 'PLx'}},
      ],
    });

    expect(list, hasLength(1));
    expect(list.single.id, 'abc123');
    expect(list.single.title, 'Best bicep workout');
    expect(list.single.thumbnailUrl, 'https://i.ytimg.com/large.jpg',
        reason: 'the second thumbnail is the larger one');
  });

  test('a video with one thumbnail uses it', () {
    final list = VideoSummary.listFrom({
      'contents': [
        {
          'video': {
            'videoId': 'x',
            'thumbnails': [
              {'url': 'only.jpg'}
            ],
          },
        },
      ],
    });
    expect(list.single.thumbnailUrl, 'only.jpg');
    expect(list.single.title, '');
  });

  test('a video with no id is skipped, since it cannot be played', () {
    expect(
      VideoSummary.listFrom({
        'contents': [
          {'video': {'title': 'no id'}},
          {'video': {'videoId': '', 'title': 'empty id'}},
        ],
      }),
      isEmpty,
    );
  });

  test('malformed responses yield nothing instead of throwing', () {
    expect(VideoSummary.listFrom(null), isEmpty);
    expect(VideoSummary.listFrom('error'), isEmpty);
    expect(VideoSummary.listFrom({'contents': 'nope'}), isEmpty);
    expect(VideoSummary.listFrom({'contents': [1, 'two', null]}), isEmpty);
  });

  test('every muscle has a search term and a lookup that finds it', () {
    for (final m in Muscle.all) {
      expect(m.searchTerm.trim(), isNotEmpty, reason: m.slug);
      expect(Muscle.bySlug(m.slug), same(m));
    }
    expect(Muscle.bySlug('head'), isNull);
    expect(Muscle.bySlug(null), isNull);
  });
}
