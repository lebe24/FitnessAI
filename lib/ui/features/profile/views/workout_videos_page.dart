import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/history_analytics.dart';
import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/core/widgets/centered_title_bar.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/video/views/video_catalog_card.dart';
import 'package:fitness/ui/features/video/views/video_flow.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kLime = Color(0xFFCCFF00);
const _kDim = Color(0x80FFFFFF);

/// The empty state's camera icon and its footnote, which are quieter than any
/// colour the other screens use.
const _kEmptyIcon = Color(0xFF3A4050);
const _kFootnote = Color(0xFF5B5F6B);

/// Every workout video saved on this phone, as a grid, and the one control to
/// remove them all. Videos live only on the device, so this is also the answer
/// to "where is my footage and how do I get rid of it".
class WorkoutVideosPage extends StatefulWidget {
  final ExerciseVideoStorage? storage;
  const WorkoutVideosPage({super.key, this.storage});

  @override
  State<WorkoutVideosPage> createState() => _WorkoutVideosPageState();
}

class _WorkoutVideosPageState extends State<WorkoutVideosPage> {
  late final ExerciseVideoStorage _storage = widget.storage ?? sl<ExerciseVideoStorage>();

  /// Null until the first read.
  List<ExerciseVideo>? _videos;

  /// So a reload after a change does not count as opening the page again.
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    Analytics.screen('workout_videos');
    _storage.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _storage.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final all = await _storage.all();
    if (!mounted) return;
    if (!_reported) {
      _reported = true;
      HistoryAnalytics.videosOpened(count: all.length, analysed: all.where((v) => v.isAnalysed).length);
    }
    setState(() => _videos = all);
  }

  static String size(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0F14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete all your videos?',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
        content: Text(
          'Every video and form rating will be removed from this phone. This can’t be undone.',
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.45, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Keep', style: GoogleFonts.inter(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete all', style: GoogleFonts.inter(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final count = _videos?.length ?? 0;
    await _storage.deleteAll();
    HistoryAnalytics.videosDeletedAll(count: count);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('All videos deleted', style: GoogleFonts.inter(fontSize: 13)),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final videos = _videos;
    final count = videos?.length;
    return Scaffold(
      backgroundColor: kBodyBg,
      body: SafeArea(
        child: Column(
          children: [
            const CenteredTitleBar(title: 'Workout videos'),
            Expanded(
              child: videos == null
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kLime))
                  : videos.isEmpty
                      ? const _EmptyState()
                      : _Catalog(videos: videos, storage: _storage),
            ),
            if (count != null && count > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: GestureDetector(
                  onTap: _deleteAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text('Delete all my videos',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The grid of videos with its count, the privacy note and the footnote.
class _Catalog extends StatelessWidget {
  final List<ExerciseVideo> videos;
  final ExerciseVideoStorage storage;
  const _Catalog({required this.videos, required this.storage});

  @override
  Widget build(BuildContext context) {
    final bytes = videos.fold<int>(0, (t, v) => t + v.sizeBytes);
    final n = videos.length;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
            child: Text(
              '$n ${n == 1 ? 'video' : 'videos'} · ${_WorkoutVideosPageState.size(bytes)} on this phone',
              style: bodyText(12, color: kBodyMuted),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: kVideoCatalogCardHeight,
            ),
            itemCount: n,
            itemBuilder: (_, i) => VideoCatalogCard(
              video: videos[i],
              storage: storage,
              onTap: () => openVideo(context, videos[i]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
            child: Column(
              children: [
                Text(
                  'Your videos are stored only on this phone. They are never uploaded: when '
                  'you analyse one, a few small still frames are sent to be rated and are not kept.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, height: 1.55, color: _kDim),
                ),
                const SizedBox(height: 10),
                Text(
                  'Deleting the app deletes your videos too.',
                  textAlign: TextAlign.center,
                  style: bodyText(12, color: kBodyMuted, weight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Nothing saved yet.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: kBodyCard,
                shape: BoxShape.circle,
                border: Border.all(color: kBodyBorder),
              ),
              child: const Icon(Icons.videocam_outlined, size: 56, color: _kEmptyIcon),
            ),
            const SizedBox(height: 28),
            Text('No videos saved', textAlign: TextAlign.center, style: bodyHeading(20)),
            const SizedBox(height: 10),
            Text(
              'Film a set from any exercise page and it stays on this phone.',
              textAlign: TextAlign.center,
              style: bodyText(14, color: kBodyMuted, weight: FontWeight.w400, height: 1.5),
            ),
            const SizedBox(height: 34),
            Text(
              'Deleting the app deletes your videos too.',
              textAlign: TextAlign.center,
              style: bodyText(12, color: _kFootnote, weight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}
