import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_events.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/domain/models/session_volume.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens (same as exercise_hero_page.dart) ────────────────────────────
const _kLime = Color(0xFFCCFF00);
const _kCard = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kDimWhite = Color(0x80FFFFFF);
const _kAmber = Color(0xFFFFAA00);

/// How many earlier visits sit under the "last time" card before the rest move
/// behind "See all".
const _kInline = 3;

/// `Today`, `Yesterday`, `3 days ago`, then a plain date.
@visibleForTesting
String historyDayLabel(DateTime date, DateTime now) {
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

/// "History" on the exercise page: what was done the last few times this
/// movement was logged, so the next set has a number to beat.
///
/// Takes the history as a future so the page can start loading it the moment
/// it opens and reuse the same answer to pre-fill the log dialog.
class ExerciseHistorySection extends StatelessWidget {
  final String exerciseName;

  /// Null in the result means the sessions could not be read.
  final Future<ExerciseHistory?> history;
  final VoidCallback onRetry;

  /// Injectable for tests; defaults to the current time.
  final DateTime? now;

  /// Shows a card that opens the paywall instead of the history. The history is
  /// a Pro feature: a free user sees what it is, not their numbers.
  final bool locked;

  const ExerciseHistorySection({
    super.key,
    required this.exerciseName,
    required this.history,
    required this.onRetry,
    this.now,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 18, color: _kLime),
            const SizedBox(width: 8),
            Text(
              'History',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            PremiumBadge(visible: locked),
          ],
        ),
        const SizedBox(height: 12),
        if (locked)
          const PremiumLockedCard(feature: PremiumFeature.exerciseHistory)
        else
        FutureBuilder<ExerciseHistory?>(
          future: history,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const _Loading();
            }
            final data = snap.data;
            if (snap.hasError || data == null) {
              return _Message(
                icon: Icons.cloud_off_rounded,
                text: "Couldn't load your history.",
                action: 'Try again',
                onAction: onRetry,
              );
            }
            if (data.isEmpty) {
              return const _Message(
                icon: Icons.fitness_center_rounded,
                text: 'No history for this exercise yet. Log it once and '
                    'your past sessions will show up here.',
              );
            }
            return _Body(
              history: data,
              exerciseName: exerciseName,
              now: now ?? DateTime.now(),
            );
          },
        ),
      ],
    );
  }
}

// ── States ────────────────────────────────────────────────────────────────────

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      alignment: Alignment.center,
      decoration: _cardDecoration(),
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(color: _kLime, strokeWidth: 2.2),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.text,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _kDimWhite),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  fontSize: 13, height: 1.45, color: _kDimWhite),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kLime)),
            ),
        ],
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final ExerciseHistory history;
  final String exerciseName;
  final DateTime now;

  const _Body({
    required this.history,
    required this.exerciseName,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final entries = history.entries;
    final older = entries.skip(1).take(_kInline).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LastTimeCard(
          entry: entries.first,
          change: history.changeAt(0),
          now: now,
        ),
        if (older.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            decoration: _cardDecoration(),
            child: Column(
              children: [
                for (var i = 0; i < older.length; i++) ...[
                  _OlderRow(
                    entry: older[i],
                    change: history.changeAt(i + 1),
                    now: now,
                  ),
                  if (i < older.length - 1)
                    const Divider(height: 1, thickness: 1, color: _kBorder),
                ],
              ],
            ),
          ),
        ],
        if (entries.length > 1 + _kInline) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => _showAll(context),
              child: Text(
                'See all ${entries.length} sessions',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kLime),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showAll(BuildContext context) {
    Analytics.track(
        AnalyticsEvents.exerciseHistoryOpened, {'sessions': history.length});
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AllSheet(history: history, exerciseName: exerciseName, now: now),
    );
  }
}

class _LastTimeCard extends StatelessWidget {
  final ExerciseHistoryEntry entry;
  final HistoryChange? change;
  final DateTime now;

  const _LastTimeCard({
    required this.entry,
    required this.change,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final best = entry.bestSet;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(highlight: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Last time',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kLime)),
              const SizedBox(width: 8),
              Text(historyDayLabel(entry.date, now),
                  style:
                      GoogleFonts.inter(fontSize: 12, color: _kDimWhite)),
              const Spacer(),
              if (change != null) _ChangeBadge(change: change!),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final s in entry.sets) _SetChip(set: s)],
          ),
          if (best != null || entry.volumeKg > 0) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 28,
              runSpacing: 10,
              children: [
                if (best != null)
                  _MiniStat(label: 'Best set', value: best.label),
                if (entry.volumeKg > 0)
                  _MiniStat(
                      label: 'Volume',
                      value: '${formatKg(entry.volumeKg)} kg'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OlderRow extends StatelessWidget {
  final ExerciseHistoryEntry entry;
  final HistoryChange? change;
  final DateTime now;

  const _OlderRow({
    required this.entry,
    required this.change,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final best = entry.bestSet;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(historyDayLabel(entry.date, now),
                style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70)),
          ),
          Expanded(
            child: Text(
              '${entry.sets.length} ${entry.sets.length == 1 ? 'set' : 'sets'}'
              '${best != null ? ' · best ${best.label}' : ''}',
              style: GoogleFonts.inter(fontSize: 12.5, color: _kDimWhite),
            ),
          ),
          if (change != null) _ChangeBadge(change: change!, compact: true),
        ],
      ),
    );
  }
}

class _AllSheet extends StatelessWidget {
  final ExerciseHistory history;
  final String exerciseName;
  final DateTime now;

  const _AllSheet({
    required this.history,
    required this.exerciseName,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0C12),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      exerciseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                  Text('${history.length} sessions',
                      style:
                          GoogleFonts.inter(fontSize: 12, color: _kDimWhite)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                itemCount: history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _LastTimeCard(
                  entry: history.entries[i],
                  change: history.changeAt(i),
                  now: now,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pieces ────────────────────────────────────────────────────────────────────

BoxDecoration _cardDecoration({bool highlight = false}) => BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: highlight ? _kLime.withValues(alpha: 0.28) : _kBorder,
      ),
    );

class _SetChip extends StatelessWidget {
  final LoggedSet set;
  const _SetChip({required this.set});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: _kLime.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kLime.withValues(alpha: 0.2)),
      ),
      child: Text(
        set.label,
        style: GoogleFonts.inter(
            fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 11, color: _kDimWhite)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ],
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  final HistoryChange change;
  final bool compact;
  const _ChangeBadge({required this.change, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (change.trend) {
      HistoryTrend.up => (_kLime, Icons.arrow_upward_rounded),
      HistoryTrend.down => (_kAmber, Icons.arrow_downward_rounded),
      HistoryTrend.same => (_kDimWhite, Icons.remove_rounded),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(change.label,
              style: GoogleFonts.inter(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
