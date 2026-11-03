import 'package:fitness/data/services/video/exercise_video_storage.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBg = Color(0xFF0A0C12);
const _kCard = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kLime = Color(0xFFCCFF00);
const _kDim = Color(0x80FFFFFF);

/// What the workout videos take up on this phone, and the one control to remove
/// them all. Videos live only on the device, so this is also the answer to
/// "where is my footage and how do I get rid of it".
class WorkoutVideosPage extends StatefulWidget {
  final ExerciseVideoStorage? storage;
  const WorkoutVideosPage({super.key, this.storage});

  @override
  State<WorkoutVideosPage> createState() => _WorkoutVideosPageState();
}

class _WorkoutVideosPageState extends State<WorkoutVideosPage> {
  late final ExerciseVideoStorage _storage = widget.storage ?? sl<ExerciseVideoStorage>();
  int? _count;
  int _bytes = 0;

  @override
  void initState() {
    super.initState();
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
    final bytes = all.fold<int>(0, (t, v) => t + v.sizeBytes);
    if (!mounted) return;
    setState(() {
      _count = all.length;
      _bytes = bytes;
    });
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
    await _storage.deleteAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('All videos deleted', style: GoogleFonts.inter(fontSize: 13)),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final count = _count;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Workout videos',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.videocam_outlined, color: _kLime),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count == null
                            ? 'Loading…'
                            : count == 0
                                ? 'No videos saved'
                                : '$count ${count == 1 ? 'video' : 'videos'}',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      if (count != null && count > 0)
                        Text('${size(_bytes)} on this phone',
                            style: GoogleFonts.inter(fontSize: 13, color: _kDim)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your videos are stored only on this phone. They are never uploaded: when '
            'you analyse one, a few small still frames are sent to be rated and are not kept. '
            'Deleting the app deletes your videos too.',
            style: GoogleFonts.inter(fontSize: 13, height: 1.55, color: _kDim),
          ),
          const SizedBox(height: 24),
          if (count != null && count > 0)
            GestureDetector(
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
        ],
      ),
    );
  }
}
