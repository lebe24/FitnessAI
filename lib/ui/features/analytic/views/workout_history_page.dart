import 'package:fitness/data/models/workout_log/workout_log_model.dart';
import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/history_analytics.dart';
import 'package:fitness/data/services/workout_log/session_supabase_source.dart';
import 'package:fitness/data/services/workout_log/workout_log_remote_service.dart';
import 'package:fitness/domain/models/history_months.dart';
import 'package:fitness/domain/models/session_feedback.dart';
import 'package:fitness/domain/models/session_volume.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/analytic/views/body/body_actions.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/analytic/views/session_detail_page.dart';
import 'package:fitness/ui/features/analytic/views/session_history_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Loads every logged session. Supabase first: the same rows, without waiting
/// on a Cloud Run cold start. Falls back to the backend when the direct read
/// fails, so a Supabase outage degrades rather than empties the page.
Future<List<WorkoutSessionModel>> loadAllSessions() async {
  final direct = await sl<SessionSupabaseSource>().listSessions(limit: 200);
  // The backend caps limit at 100: asking for more is a 422, not a larger page.
  return direct ?? await sl<WorkoutLogRemoteDataSource>().listSessions(limit: 100);
}

/// Every logged session, newest first, filtered by month. Tapping one opens it.
///
/// The analytics chart shows the last eight sessions and answers "is the load
/// going up". This answers "what did I actually do", which the chart cannot:
/// a bar has one number in it, and a session has thirty.
class WorkoutHistoryPage extends StatefulWidget {
  /// Where the sessions come from. Tests and the preview pass their own.
  final Future<List<WorkoutSessionModel>> Function()? loader;

  /// Forces the unit. When null the saved kg/lb choice is used.
  final bool? imperial;

  const WorkoutHistoryPage({super.key, this.loader, this.imperial});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  List<WorkoutSessionModel> _sessions = [];
  bool _loading = true;
  bool _failed = false;
  late bool _imperial = widget.imperial ?? false;

  /// The month being shown, or null for every session.
  HistoryMonth? _month;
  bool _monthChosen = false;

  /// So refreshing does not count as opening the history again.
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    Analytics.screen('workout_history');
    if (widget.imperial == null) {
      BodyUnitPref.load().then((v) {
        if (mounted && v != null) setState(() => _imperial = v);
      });
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final loaded = await (widget.loader ?? loadAllSessions)();
      final sessions = [...loaded]..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
      if (!mounted) return;
      final months = HistoryMonth.distinct(sessions.map((s) => s.sessionDate));
      if (!_reported) {
        _reported = true;
        HistoryAnalytics.opened(sessions: sessions.length, months: months.length);
      }
      setState(() {
        _sessions = sessions;
        _loading = false;
        _failed = false;
        // Open on the newest month, as the design does. A choice the user has
        // made stays unless that month is gone.
        final keep = _monthChosen && (_month == null || months.contains(_month));
        if (!keep) {
          _month = months.isEmpty ? null : months.last;
          _monthChosen = false;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _select(HistoryMonth? month) {
    HistoryAnalytics.monthSelected(all: month == null);
    setState(() {
      _month = month;
      _monthChosen = true;
    });
  }

  void _open(WorkoutSessionModel s) {
    HistoryAnalytics.sessionOpened(
      exercises: SessionVolume.exercisesOf(s).length,
      hasFeedback: !SessionFeedback.fromMap(s.feedback).isEmpty,
    );
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SessionDetailPage(session: s, imperial: _imperial, history: _sessions),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final months = HistoryMonth.distinct(_sessions.map((s) => s.sessionDate));
    final visible = _month == null ? _sessions : [for (final s in _sessions) if (_month!.contains(s.sessionDate)) s];

    return Scaffold(
      backgroundColor: kBodyBg,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            if (!_loading && !_failed && months.isNotEmpty)
              _MonthChips(months: months, selected: _month, onSelect: _select),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kBodyLime))
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
                              color: kBodyLime,
                              backgroundColor: kBodyCard,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                                itemCount: visible.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (_, i) {
                                  final card = SessionHistoryCard(
                                    session: visible[i],
                                    imperial: _imperial,
                                    onTap: () => _open(visible[i]),
                                  );
                                  // Only the first screenful eases in; later cards
                                  // build as they scroll and should just appear.
                                  if (i >= 6) return card;
                                  return card
                                      .animate(key: ValueKey('${_month?.label()}-$i'))
                                      .fadeIn(delay: (i * 40).ms, duration: 280.ms)
                                      .slideY(begin: 0.05, end: 0, delay: (i * 40).ms, duration: 280.ms);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    button: true,
                    label: 'Back',
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kBodyCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: kBodyBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                Text('Workout history', style: bodyHeading(17)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('Every session you log', style: bodyText(13, color: kBodyMuted, weight: FontWeight.w400)),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

/// `All` and one chip per month that has sessions, scrolling sideways.
class _MonthChips extends StatefulWidget {
  final List<HistoryMonth> months;
  final HistoryMonth? selected;
  final ValueChanged<HistoryMonth?> onSelect;

  const _MonthChips({required this.months, required this.selected, required this.onSelect});

  @override
  State<_MonthChips> createState() => _MonthChipsState();
}

class _MonthChipsState extends State<_MonthChips> {
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _reveal();
  }

  @override
  void didUpdateWidget(covariant _MonthChips old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) _reveal();
  }

  /// Brings the selected chip into view, since the newest month is last and may
  /// start off-screen.
  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _selectedKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 200), alignment: 0.5, curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final withYear = HistoryMonth.spansYears(widget.months);
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _Chip(
            key: widget.selected == null ? _selectedKey : null,
            label: 'All',
            selected: widget.selected == null,
            onTap: () => widget.onSelect(null),
          ),
          for (final m in widget.months) ...[
            const SizedBox(width: 6),
            _Chip(
              key: m == widget.selected ? _selectedKey : null,
              label: m.label(withYear: withYear),
              selected: m == widget.selected,
              onTap: () => widget.onSelect(m),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? kBodyLime : kBodyChip,
            borderRadius: BorderRadius.circular(17),
            border: selected ? null : Border.all(color: kBodyBorder),
          ),
          child: Text(label, style: bodyText(13, color: selected ? kBodyBg : kBodySoft)),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  const _Message({required this.icon, required this.title, required this.body, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: kBodyLime.withValues(alpha: 0.4)),
              const SizedBox(height: 14),
              Text(title, textAlign: TextAlign.center, style: bodyHeading(15)),
              const SizedBox(height: 6),
              Text(body, textAlign: TextAlign.center, style: bodyText(12.5, color: kBodyMuted, height: 1.5)),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                    decoration: BoxDecoration(
                      color: kBodyLime.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: kBodyLime.withValues(alpha: 0.35)),
                    ),
                    child: Text('Try again', style: bodyText(13, color: kBodyLime, weight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
