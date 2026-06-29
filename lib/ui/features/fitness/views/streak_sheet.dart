import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kLime      = Color(0xFFCCFF00);
const _kFireStart = Color(0xFFFF6B00);
const _kSurface   = Color(0xFF0A0C12);
const _kCard      = Color(0xFF111318);
const _kDimWhite  = Color(0x80FFFFFF);

const _kMilestones = [3, 7, 14, 30, 60, 100, 200, 365];

int _nextMilestone(int streak) {
  for (final m in _kMilestones) {
    if (streak < m) return m;
  }
  return streak + 50;
}

String _streakMessage(int streak) {
  if (streak == 0)  return 'Start today — day 1 is always the hardest.';
  if (streak < 3)   return 'You\'ve started. Keep the chain alive.';
  if (streak < 7)   return 'Building momentum — don\'t break it now.';
  if (streak < 14)  return 'One week strong. You\'re forming a real habit.';
  if (streak < 30)  return 'Two weeks in. This is becoming your lifestyle.';
  if (streak < 60)  return 'A full month of consistency. Unstoppable.';
  if (streak < 100) return 'Two months of dedication. Legendary.';
  return 'Elite level. You are an inspiration.';
}

class StreakSheet extends StatelessWidget {
  final int streak;
  const StreakSheet({super.key, required this.streak});

  int get _next => _nextMilestone(streak);

  String get _milestoneLabel {
    if (streak == 0) return 'Start your streak today';
    final left = _next - streak;
    return '$left day${left == 1 ? '' : 's'} until $_next-day milestone';
  }

  @override
  Widget build(BuildContext context) {
    final progress = streak == 0 ? 0.0 : (streak / _next).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(),
          const SizedBox(height: 8),
          _FireIcon(),
          const SizedBox(height: 20),
          _StreakCounter(streak: streak),
          const SizedBox(height: 28),
          _MilestoneProgress(
            label: _milestoneLabel,
            progress: progress,
          ),
          const SizedBox(height: 20),
          _MessageCard(message: _streakMessage(streak)),
          const SizedBox(height: 24),
          _CloseButton(streak: streak),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _FireIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFFFCC00), _kFireStart],
          ),
          boxShadow: [
            BoxShadow(
              color: _kFireStart.withValues(alpha: 0.45),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.local_fire_department_rounded,
          color: Colors.white,
          size: 40,
        ),
      );
}

class _StreakCounter extends StatelessWidget {
  final int streak;
  const _StreakCounter({required this.streak});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            '$streak',
            style: GoogleFonts.poppins(
              fontSize: 80,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'day streak',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _kDimWhite,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
}

class _MilestoneProgress extends StatelessWidget {
  final String label;
  final double progress;
  const _MilestoneProgress({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, color: _kDimWhite),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kLime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(_kLime),
            ),
          ),
        ],
      );
}

class _MessageCard extends StatelessWidget {
  final String message;
  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      );
}

class _CloseButton extends StatelessWidget {
  final int streak;
  const _CloseButton({required this.streak});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            side: const BorderSide(color: _kLime, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            streak == 0 ? 'Start Today' : 'Keep Going',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kLime,
            ),
          ),
        ),
      );
}
