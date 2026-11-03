import 'dart:async';
import 'dart:typed_data';

import 'package:fitness/data/services/video/video_import_service.dart';
import 'package:fitness/data/services/video/video_notice_storage.dart';
import 'package:fitness/data/services/video/video_tools.dart';
import 'package:fitness/ui/features/video/views/video_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Add a video ───────────────────────────────────────────────────────────────

/// Record or choose from the library. Null if cancelled.
Future<VideoSource?> showAddVideoSheet(BuildContext context) {
  return showVideoSheet<VideoSource>(
    context,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add a video',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text('One set per clip works best. Up to 1 minute is kept.',
              style: GoogleFonts.inter(fontSize: 13, color: kVideoDim)),
          const SizedBox(height: 18),
          VideoPrimaryButton(
            label: 'Record',
            icon: Icons.videocam_rounded,
            onTap: () => Navigator.of(context).pop(VideoSource.record),
          ),
          const SizedBox(height: 10),
          VideoSecondaryButton(
            label: 'Choose from library',
            icon: Icons.photo_library_outlined,
            onTap: () => Navigator.of(context).pop(VideoSource.library),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── How to film ───────────────────────────────────────────────────────────────

/// The recording guide. Shown before the first recording and from a "Tips" link
/// afterwards. Returns true if the user chose to go on (when [forRecording]).
Future<bool> showRecordingTips(BuildContext context, {bool forRecording = false}) async {
  final go = await showVideoSheet<bool>(
    context,
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to film a set',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text('The angle matters more than anything else for a good rating.',
              style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: kVideoDim)),
          const SizedBox(height: 18),
          const _Tip(Icons.swap_horiz_rounded, 'Film from the side',
              'A side view shows your back, depth and bar path. From behind or in front, the AI can only judge part of it.'),
          const _Tip(Icons.height_rounded, 'Phone at hip height, about 3 m away',
              'Prop it against a bag or rack so it stays steady.'),
          const _Tip(Icons.accessibility_new_rounded, 'Whole body in frame',
              'Head to feet, with the bar or weights included.'),
          const _Tip(Icons.visibility_off_outlined, 'Nothing in front of the lens',
              'Keep plates, racks and people out of the way.'),
          const _Tip(Icons.person_outline_rounded, 'Just you in the shot',
              'Other people in the frame can be confused with you, and it is kinder not to film them.'),
          const _Tip(Icons.looks_one_outlined, 'One set per clip',
              'Start recording just before you lift and stop just after.'),
          const SizedBox(height: 10),
          VideoPrimaryButton(
            label: forRecording ? 'Got it, record' : 'Got it',
            onTap: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ),
  );
  await VideoNoticeStorage.markTipsSeen();
  return go ?? false;
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Tip(this.icon, this.title, this.body);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kVideoLime.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: kVideoLime),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(body,
                      style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: kVideoDim)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Privacy notice before the first analysis ──────────────────────────────────

/// True once the user has accepted the notice (now or earlier).
Future<bool> ensureAnalysisNotice(BuildContext context) async {
  if (await VideoNoticeStorage.analysisNoticeAccepted()) return true;
  if (!context.mounted) return false;
  final ok = await showVideoSheet<bool>(
    context,
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Before your first analysis',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 14),
          const _Tip(Icons.phone_iphone_rounded, 'Your video stays on this phone',
              'It is never uploaded. Deleting the app deletes your videos.'),
          const _Tip(Icons.image_outlined, 'A few still frames are sent',
              'About 8 to 12 small pictures, cropped around you where possible, go to our AI provider to be rated. They are not kept.'),
          const _Tip(Icons.groups_outlined, 'Other people in the shot',
              'Frames are cropped to you, but bystanders can still appear. Try not to film other people.'),
          const _Tip(Icons.health_and_safety_outlined, 'Guidance, not medical advice',
              'Ratings are for general fitness guidance. Stop if something hurts and see a professional.'),
          const SizedBox(height: 10),
          VideoPrimaryButton(
            label: 'Continue',
            onTap: () => Navigator.of(context).pop(true),
          ),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Not now', style: GoogleFonts.inter(color: Colors.white54)),
            ),
          ),
        ],
      ),
    ),
  );
  if (ok == true) {
    await VideoNoticeStorage.markAnalysisNoticeAccepted();
    return true;
  }
  return false;
}

// ── Choosing which minute to keep ─────────────────────────────────────────────

/// For a clip over a minute: the user picks which minute to keep. Returns the
/// start in milliseconds, or null if cancelled.
Future<int?> showTrimSheet(BuildContext context, PickedVideo picked, VideoTools tools) {
  return showVideoSheet<int>(
    context,
    builder: (context) => _TrimSheet(picked: picked, tools: tools),
  );
}

class _TrimSheet extends StatefulWidget {
  final PickedVideo picked;
  final VideoTools tools;
  const _TrimSheet({required this.picked, required this.tools});

  @override
  State<_TrimSheet> createState() => _TrimSheetState();
}

class _TrimSheetState extends State<_TrimSheet> {
  late double _start = 0; // ms
  Future<Uint8List?>? _preview;
  Timer? _debounce;

  int get _total => widget.picked.info.durationMs;
  double get _maxStart => (_total - VideoImportService.maxClipMs).clamp(0, _total).toDouble();

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _loadPreview() {
    _preview = _thumbnail();
  }

  Future<Uint8List?> _thumbnail() async {
    try {
      return await widget.tools
          .thumbnail(widget.picked.path, atMs: _start.round(), maxEdge: 360);
    } on VideoToolsException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final end = (_start + VideoImportService.maxClipMs).clamp(0, _total).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick your minute',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            'This clip is ${videoDuration(widget.picked.info.duration)}. '
            'Up to 1 minute is kept: slide to the set you want.',
            style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: kVideoDim),
          ),
          const SizedBox(height: 16),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 200,
                child: FutureBuilder<Uint8List?>(
                  future: _preview,
                  builder: (context, snap) {
                    final data = snap.data;
                    if (data == null) {
                      return const AspectRatio(
                        aspectRatio: 9 / 16,
                        child: ColoredBox(
                          color: kVideoCard2,
                          child: Icon(Icons.videocam_rounded, color: Colors.white24),
                        ),
                      );
                    }
                    return Image.memory(data, fit: BoxFit.contain, gaplessPlayback: true);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _start.clamp(0, _maxStart),
            min: 0,
            max: _maxStart <= 0 ? 1 : _maxStart,
            activeColor: kVideoLime,
            inactiveColor: Colors.white12,
            onChanged: _maxStart <= 0
                ? null
                : (v) {
                    setState(() => _start = v);
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 150), () {
                      if (mounted) setState(_loadPreview);
                    });
                  },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(videoDuration(Duration(milliseconds: _start.round())),
                  style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white70)),
              Text('to ${videoDuration(Duration(milliseconds: end))}',
                  style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 14),
          VideoPrimaryButton(
            label: 'Keep this minute',
            onTap: () => Navigator.of(context).pop(_start.round()),
          ),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Saving progress ───────────────────────────────────────────────────────────

/// Shown while a clip is trimmed and compressed. [run] does the work and gets a
/// progress callback; [onCancel] stops it.
Future<T?> showSavingDialog<T>(
  BuildContext context, {
  required Future<T> Function(void Function(double) onProgress) run,
  required Future<void> Function() onCancel,
}) async {
  final progress = ValueNotifier<double>(0);
  var closed = false;

  final dialog = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: const Color(0xFF0D0F14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, p, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: p <= 0 ? null : p,
                    color: kVideoLime,
                    backgroundColor: Colors.white12,
                  ),
                ),
                const SizedBox(height: 18),
                Text('Saving your video',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  p <= 0 ? 'Getting it ready…' : 'Compressing… ${(p * 100).round()}%',
                  style: GoogleFonts.inter(fontSize: 13, color: kVideoDim),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => onCancel(),
                  child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  try {
    return await run((p) => progress.value = p);
  } finally {
    if (!closed && context.mounted) {
      closed = true;
      Navigator.of(context, rootNavigator: true).pop();
    }
    await dialog;
    progress.dispose();
  }
}
