import 'dart:io';

import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/domain/models/exercise_video.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens (same as the exercise page) ──────────────────────────────────
const kVideoLime = Color(0xFFCCFF00);
const kVideoCard = Color(0xFF111318);
const kVideoCard2 = Color(0xFF161B26);
const kVideoBorder = Color(0xFF1E2330);
const kVideoDim = Color(0x80FFFFFF);
const kVideoAmber = Color(0xFFFFAA00);
const kVideoRed = Color(0xFFFF6B6B);

/// The colour for a 1–10 score: lime for good, amber for middling, red below 5.
Color scoreColor(int? score) {
  if (score == null) return Colors.white38;
  if (score >= 7) return kVideoLime;
  if (score >= 5) return kVideoAmber;
  return kVideoRed;
}

String videoDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String videoDate(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final days = today.difference(DateTime(date.year, date.month, date.day)).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final base = '${date.day} ${months[date.month - 1]}';
  return date.year == now.year ? base : '$base ${date.year}';
}

/// `7/10`, tinted by how good it is. When the result is low confidence it says
/// so with a "~", so a rear-view clip never looks like a firm verdict.
class RatingChip extends StatelessWidget {
  final FormAnalysis analysis;
  final bool compact;
  const RatingChip({super.key, required this.analysis, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final score = analysis.overallScore;
    final color = scoreColor(score);
    final unsure = analysis.confidence == Confidence.low;
    final label = score == null ? 'Rated' : '${unsure ? '~' : ''}$score/10';
    return Semantics(
      label: score == null
          ? 'Analysed'
          : 'Form rating $score out of 10${unsure ? ', low confidence' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 2 : 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: compact ? 10 : 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A video's thumbnail from storage, or an icon if there isn't one.
class VideoThumbnail extends StatelessWidget {
  final ExerciseVideo video;
  final ExerciseVideoStorage storage;
  final BoxFit fit;
  const VideoThumbnail({
    super.key,
    required this.video,
    required this.storage,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: storage.thumbnailFile(video),
      builder: (context, snap) {
        final file = snap.data;
        final usable = file != null && file.existsSync() && file.lengthSync() > 0;
        if (!usable) return const _ThumbFallback();
        return Image.file(
          file,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const _ThumbFallback(),
        );
      },
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) => Container(
        color: kVideoCard2,
        alignment: Alignment.center,
        child: const Icon(Icons.videocam_rounded, color: Colors.white24, size: 28),
      );
}

/// A bottom sheet in the app's style: dark, rounded, with a grab handle.
Future<T?> showVideoSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(child: builder(context)),
          ],
        ),
      ),
    ),
  );
}

/// The lime call to action used across the video screens.
class VideoPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const VideoPrimaryButton({super.key, required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: enabled ? kVideoLime : Colors.white12,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: enabled ? Colors.black : Colors.white38),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: enabled ? Colors.black : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const VideoSecondaryButton({super.key, required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.white70),
                  const SizedBox(width: 8),
                ],
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white70)),
              ],
            ),
          ),
        ),
      );
}
