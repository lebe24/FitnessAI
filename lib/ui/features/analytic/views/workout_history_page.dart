import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/workout_log/session_supabase_source.dart';
import 'package:fitness/data/services/workout_log/workout_log_remote_service.dart';
import 'package:fitness/domain/models/session_volume.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBg = Color(0xFF0A0C12);
const _kCard = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kSub = Color(0x80FFFFFF);
const _kLime = Color(0xFFCCFF00);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Every logged session, newest first, expandable down to individual sets.
///
/// The analytics chart shows the last eight sessions and answers "is the load
/// going up". This answers "what did I actually do", which the chart cannot —
/// a bar has one number in it, and a session has thirty.
class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  final _supabase = sl<SessionSupabaseSource>();
  final _remote = sl<WorkoutLogRemoteDataSource>();

  List<WorkoutSessionModel> _sessions = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Supabase first: the same rows, without waiting on a Cloud Run cold
      // start. Falls back to the backend when the direct read fails, so a
      // Supabase outage degrades rather than empties the page.
      var sessions = await _supabase.listSessions(limit: 200);

      // The backend caps limit at 100 — asking for more is a 422, not a
      // larger page.
      final resolved = sessions ?? await _remote.listSessions(limit: 100);
      resolved.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
      if (!mounted) return;
      setState(() {
        _sessions = resolved;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(count: _sessions.length),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kLime))
                  : _failed
                      ? _Message(
                          icon: Icons.cloud_off_rounded,
                          title: "Couldn't load your history",
                          body: 'Check your connection and try again.',
                          onRetry: _load,
                        )
                      : _sessions.isEmpty
                          ? const _Message(
                              icon: Icons.fitness_center_rounded,
                              title: 'No sessions yet',
                              body: 'Log a workout and it will appear here.',
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: _kLime,
                              backgroundColor: _kCard,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 32),
                                itemCount: _sessions.length,
                                itemBuilder: (_, i) =>
                                    _SessionCard(session: _sessions[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final int count;
  const _AppBar({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 15, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Workout history',
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1)),
                const SizedBox(height: 3),
                Text(
                  count == 0
                      ? 'Every session you log'
                      : '$count session${count == 1 ? '' : 's'} logged',
                  style: GoogleFonts.inter(fontSize: 12, color: _kSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One session: summary always visible, exercises on tap.
class _SessionCard extends StatefulWidget {
  final WorkoutSessionModel session;
  const _SessionCard({required this.session});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final v = SessionVolume.fromSession(widget.session);
    final exercises = SessionVolume.exercisesOf(widget.session);
    final d = v.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _open ? _kLime.withValues(alpha: 0.3) : _kBorder),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: exercises.isEmpty
                ? null
                : () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Date block
                  Container(
                    width: 46,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _kLime.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Column(
                      children: [
                        Text('${d.day}',
                            style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _kLime,
                                height: 1)),
                        Text(_months[d.month - 1],
                            style: GoogleFonts.inter(
                                fontSize: 10, color: _kLime)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.dayLabel?.isNotEmpty == true
                              ? v.dayLabel!
                              : 'Session',
                          style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (v.exerciseCount > 0)
                              '${v.exerciseCount} exercises',
                            if (v.setCount > 0) '${v.setCount} sets',
                            if (v.durationMins > 0) '${v.durationMins} min',
                          ].join(' · '),
                          style:
                              GoogleFonts.inter(fontSize: 11.5, color: _kSub),
                        ),
                      ],
                    ),
                  ),
                  if (v.hasVolume)
                    Text(v.shortVolume,
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _kLime)),
                  if (exercises.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 20, color: Colors.white38),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Grid-rows animation avoids measuring the child.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: _open
                ? Column(
                    children: [
                      Divider(height: 1, color: _kBorder),
                      for (final e in exercises) _ExerciseRow(exercise: e),
                      const SizedBox(height: 6),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final ExerciseVolume exercise;
  const _ExerciseRow({required this.exercise});

  String _setLabel(LoggedSet s) {
    if (s.durationSec != null) return '${s.durationSec}s';
    final reps = s.reps ?? 0;
    final kg = s.weightKg;
    if (kg == null || kg == 0) return '$reps';
    return '$reps × ${kg % 1 == 0 ? kg.toInt() : kg}kg';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(exercise.name,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
              if (exercise.volumeKg > 0)
                Text('${exercise.volumeKg.round()}kg',
                    style: GoogleFonts.inter(fontSize: 11, color: _kSub)),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in exercise.sets)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    // A skipped set is dimmed rather than hidden — the gap in
                    // a session is information too.
                    color: s.wasPerformed
                        ? _kLime.withValues(alpha: 0.09)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: s.wasPerformed
                          ? _kLime.withValues(alpha: 0.22)
                          : _kBorder,
                    ),
                  ),
                  child: Text(
                    s.wasPerformed ? _setLabel(s) : 'skipped',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: s.wasPerformed ? _kLime : Colors.white24,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: _kLime.withValues(alpha: 0.4)),
              const SizedBox(height: 14),
              Text(title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 6),
              Text(body,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 12.5, height: 1.5, color: _kSub)),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 11),
                    decoration: BoxDecoration(
                      color: _kLime.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _kLime.withValues(alpha: 0.35)),
                    ),
                    child: Text('Try again',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kLime)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
