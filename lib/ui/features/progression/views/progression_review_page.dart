import 'package:fitness/domain/progression/progression_proposal.dart';
import 'package:fitness/ui/features/progression/views/progression_settings_sheet.dart';
import 'package:fitness/ui/features/progression/views/progression_theme.dart';
import 'package:flutter/material.dart';

/// Shows the update the engine proposes for the active plan, change by change,
/// and lets the user keep or drop each one before it is applied.
///
/// With no callbacks it is a self-contained preview, which is how the design
/// review runs it. In the app the callbacks do the real work: [onApply] saves
/// the update and returns whether it worked, [onUndo] reverts it, [onDismiss]
/// records "not this time", and [onSettings] opens the settings sheet.
class ProgressionReviewPage extends StatefulWidget {
  final ProgressionProposal proposal;
  final Future<bool> Function(Set<int> skipped)? onApply;
  final Future<bool> Function()? onUndo;
  final Future<void> Function()? onDismiss;
  final VoidCallback? onSettings;

  const ProgressionReviewPage({
    super.key,
    required this.proposal,
    this.onApply,
    this.onUndo,
    this.onDismiss,
    this.onSettings,
  });

  @override
  State<ProgressionReviewPage> createState() => _ProgressionReviewPageState();
}

class _ProgressionReviewPageState extends State<ProgressionReviewPage> {
  late final Set<int> _skipped = {};
  bool _applied = false;
  bool _busy = false;

  ProgressionProposal get p => widget.proposal;

  int get _chosen {
    var n = 0;
    for (var i = 0; i < p.changes.length; i++) {
      if (!p.changes[i].isHold && !_skipped.contains(i)) n++;
    }
    return n;
  }

  Future<void> _apply() async {
    final onApply = widget.onApply;
    if (onApply == null) {
      setState(() => _applied = true);
      return;
    }
    setState(() => _busy = true);
    final ok = await onApply(_skipped);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _applied = ok;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not update your plan. Try again.', style: progBody(13)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _undo() async {
    final onUndo = widget.onUndo;
    if (onUndo == null) {
      setState(() => _applied = false);
      return;
    }
    setState(() => _busy = true);
    final ok = await onUndo();
    if (!mounted) return;
    setState(() => _busy = false);
    // The proposal was built from the plan before it changed, so after an
    // undo the screen would be stale. Leave it; the card recomputes.
    if (ok) Navigator.of(context).maybePop();
  }

  Future<void> _skip() async {
    await widget.onDismiss?.call();
    if (mounted) Navigator.of(context).maybePop();
  }

  void _toggle(int i) => setState(() {
        if (!_skipped.remove(i)) _skipped.add(i);
      });

  @override
  Widget build(BuildContext context) {
    // Group by day, keeping the order the engine gave.
    final groups = <String, List<int>>{};
    for (var i = 0; i < p.changes.length; i++) {
      final c = p.changes[i];
      groups.putIfAbsent('${c.day} · ${c.dayFocus}', () => []).add(i);
    }

    return Scaffold(
      backgroundColor: kProgBg,
      body: Column(
        children: [
          _Header(proposal: p, onSettings: widget.onSettings),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                _SummaryCard(proposal: p),
                if (p.isDeload) ...[const SizedBox(height: 12), const _DeloadBanner()],
                const SizedBox(height: 12),
                const _HowWeDecide(),
                for (final entry in groups.entries) ...[
                  const SizedBox(height: 22),
                  _DayHeader(
                    title: entry.key,
                    count: entry.value.where((i) => !p.changes[i].isHold).length,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: kProgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kProgBorder),
                    ),
                    child: Column(
                      children: [
                        for (var k = 0; k < entry.value.length; k++) ...[
                          if (k > 0) const Divider(height: 1, color: kProgBorder),
                          _ChangeRow(
                            change: p.changes[entry.value[k]],
                            included: !_skipped.contains(entry.value[k]),
                            enabled: !_applied,
                            onToggle: () => _toggle(entry.value[k]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          _applied
              ? _AppliedBar(
                  version: p.toVersion,
                  busy: _busy,
                  onUndo: _undo,
                  onDone: () => Navigator.of(context).maybePop(),
                )
              : _ApplyBar(
                  chosen: _chosen,
                  total: p.actionable.length,
                  busy: _busy,
                  onApply: _chosen == 0 || _busy ? null : _apply,
                  onSkip: _busy ? null : _skip,
                ),
        ],
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ProgressionProposal proposal;
  final VoidCallback? onSettings;
  const _Header({required this.proposal, this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kProgCard,
        border: Border(bottom: BorderSide(color: kProgBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Row(
            children: [
              const ProgBackButton(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plan update', style: progHeading(20)),
                    const SizedBox(height: 2),
                    Text(
                      '${proposal.planName} · v${proposal.fromVersion} → v${proposal.toVersion}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: progBody(12, color: kProgMuted),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Update settings',
                child: GestureDetector(
                  onTap: onSettings ?? () => showProgressionSettings(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kProgBorder),
                    ),
                    child: const Icon(Icons.tune_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary ─────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final ProgressionProposal proposal;
  const _SummaryCard({required this.proposal});

  @override
  Widget build(BuildContext context) {
    final n = proposal.actionable.length;
    final accent = proposal.isDeload ? kProgAmber : kProgLime;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.06), kProgCard],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                proposal.isDeload ? 'TIME TO RECOVER' : 'READY TO PROGRESS',
                style: progBody(11, color: accent, weight: FontWeight.w700).copyWith(letterSpacing: 1.1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            proposal.isDeload
                ? 'A lighter week, then back to heavier work'
                : '$n changes to keep you moving forward',
            style: progHeading(19),
          ),
          const SizedBox(height: 6),
          Text(
            'Built from your last ${proposal.weeks} weeks of logged sets, '
            'aimed at your goal: ${proposal.goal.toLowerCase()}.',
            style: progBody(13, color: kProgMuted, height: 1.45),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(value: '${proposal.sessionsAnalysed}', label: 'Sessions'),
              const SizedBox(width: 10),
              _Stat(value: '${(proposal.adherence * 100).round()}%', label: 'Attendance'),
              const SizedBox(width: 10),
              _Stat(value: '${proposal.newPersonalBests}', label: 'New bests'),
            ],
          ),
          if (proposal.coachState != CoachState.off) ...[
            const SizedBox(height: 14),
            _CoachStatus(proposal: proposal),
          ],
        ],
      ),
    );
  }
}

/// Where the coach's review stands, in one line.
class _CoachStatus extends StatelessWidget {
  final ProgressionProposal proposal;
  const _CoachStatus({required this.proposal});

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (proposal.coachState) {
      CoachState.reviewing => (null, kProgMuted, 'Your coach is reviewing these changes…'),
      CoachState.reviewed => (
          Icons.verified_rounded,
          kProgLime,
          proposal.coachNote ?? 'Reviewed by your coach.',
        ),
      CoachState.unavailable => (
          Icons.cloud_off_rounded,
          kProgMuted,
          'Coach review is unavailable. These changes come from your training log alone.',
        ),
      CoachState.off => (null, kProgMuted, ''),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: icon == null
              ? const Padding(
                  padding: EdgeInsets.all(2),
                  child: CircularProgressIndicator(strokeWidth: 2, color: kProgMuted),
                )
              : Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: progBody(12.5, color: color == kProgLime ? Colors.white : color, height: 1.4))),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kProgBorder),
        ),
        child: Column(
          children: [
            Text(value, style: progHeading(20)),
            const SizedBox(height: 2),
            Text(label, style: progBody(11, color: kProgMuted)),
          ],
        ),
      ),
    );
  }
}

class _DeloadBanner extends StatelessWidget {
  const _DeloadBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kProgAmber.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kProgAmber.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.battery_charging_full_rounded, color: kProgAmber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This is a planned easy week. Loads and sets drop for seven days so '
              'your joints and nervous system catch up. The next update resumes progress.',
              style: progBody(12.5, color: Colors.white.withValues(alpha: 0.85), height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowWeDecide extends StatefulWidget {
  const _HowWeDecide();

  @override
  State<_HowWeDecide> createState() => _HowWeDecideState();
}

class _HowWeDecideState extends State<_HowWeDecide> {
  bool _open = false;

  static const _rules = [
    ('Heavier', 'Every set hit the top of the rep range in 2 sessions in a row.'),
    ('More reps', 'You are close to the top of the range. Reps come before weight.'),
    ('More volume', 'A muscle trails the others and your recovery is good.'),
    ('Recovery', 'Progress stalled for 3 sessions, or it is week 6 of a block.'),
    ('Hold', 'A set dropped last time. Repeat it before moving on.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kProgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kProgBorder),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: kProgMuted),
                  const SizedBox(width: 10),
                  Expanded(child: Text('How these were chosen', style: progBody(13.5, weight: FontWeight.w600))),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: kProgMuted),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  for (final (title, body) in _rules)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 86,
                            child: Text(title, style: progBody(12, weight: FontWeight.w700, color: kProgLime)),
                          ),
                          Expanded(child: Text(body, style: progBody(12, color: kProgMuted, height: 1.4))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Day group and rows ──────────────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  final String title;
  final int count;
  const _DayHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: progHeading(16)),
        const Spacer(),
        Text(
          count == 1 ? '1 change' : '$count changes',
          style: progBody(12, color: kProgMuted, weight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final PlannedChange change;
  final bool included;
  final bool enabled;
  final VoidCallback onToggle;

  const _ChangeRow({
    required this.change,
    required this.included,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorForKind(change.kind);
    final hold = change.isHold;
    final dim = hold || !included;

    return Semantics(
      container: true,
      toggled: hold ? null : included,
      label: '${change.exercise}. ${change.badge}. ${change.reason}',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: hold || !enabled ? null : onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Check(included: included, hold: hold),
              const SizedBox(width: 12),
              Expanded(
                child: Opacity(
                  opacity: dim ? 0.55 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              change.exercise,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: progBody(14.5, weight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Pill(label: change.badge, color: color, icon: iconForKind(change.kind)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (hold)
                        Text(change.before, style: progBody(12.5, color: kProgMuted))
                      else
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              change.before,
                              style: progBody(12.5, color: kProgMuted).copyWith(
                                decoration: TextDecoration.lineThrough,
                                decorationColor: kProgMuted,
                              ),
                            ),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                            Text(change.after, style: progBody(12.5, color: color, weight: FontWeight.w700)),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Text(change.reason, style: progBody(12, color: kProgMuted, height: 1.4)),
                      if (_showsCoachLine(change)) ...[
                        const SizedBox(height: 8),
                        _CoachLine(change: change),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A coach sentence goes under the rule's reason, unless it replaced it (a
/// hold the coach made already reads as the coach's).
bool _showsCoachLine(PlannedChange c) =>
    c.coachReason != null && c.coachReason!.isNotEmpty && c.coachVerdict != CoachVerdict.veto;

class _CoachLine extends StatelessWidget {
  final PlannedChange change;
  const _CoachLine({required this.change});

  @override
  Widget build(BuildContext context) {
    final eased = change.coachVerdict == CoachVerdict.soften;
    final color = eased ? kProgAmber : kProgLime;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(eased ? Icons.south_east_rounded : Icons.verified_rounded, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            eased ? 'Coach eased this: ${change.coachReason}' : 'Coach: ${change.coachReason}',
            style: progBody(12, color: color, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _Check extends StatelessWidget {
  final bool included;
  final bool hold;
  const _Check({required this.included, required this.hold});

  @override
  Widget build(BuildContext context) {
    if (hold) {
      return Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(top: 1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: kProgBorder, width: 1.5),
        ),
        child: const Icon(Icons.remove_rounded, size: 14, color: kProgMuted),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: included ? kProgLime : Colors.transparent,
        border: Border.all(color: included ? kProgLime : kProgMuted, width: 1.5),
      ),
      child: included ? const Icon(Icons.check_rounded, size: 16, color: Colors.black) : null,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Pill({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: progBody(11.5, color: color, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Bottom bars ─────────────────────────────────────────────────────────────

class _ApplyBar extends StatelessWidget {
  final int chosen;
  final int total;
  final bool busy;
  final VoidCallback? onApply;
  final VoidCallback? onSkip;
  const _ApplyBar({
    required this.chosen,
    required this.total,
    required this.busy,
    required this.onApply,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final label = busy
        ? 'Updating…'
        : chosen == 0
        ? 'Nothing selected'
        : chosen == total
            ? 'Apply all $total changes'
            : 'Apply $chosen of $total changes';
    return Container(
      decoration: const BoxDecoration(
        color: kProgCard,
        border: Border(top: BorderSide(color: kProgBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: kProgLime,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: kProgRaised,
                    disabledForegroundColor: kProgMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(label, style: progBody(15, color: onApply == null ? kProgMuted : Colors.black, weight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: onSkip,
                child: Text('Not this time', style: progBody(13, color: kProgMuted, weight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppliedBar extends StatelessWidget {
  final int version;
  final bool busy;
  final VoidCallback onUndo;
  final VoidCallback onDone;
  const _AppliedBar({
    required this.version,
    required this.busy,
    required this.onUndo,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A06),
        border: Border(top: BorderSide(color: kProgLime.withValues(alpha: 0.3))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: kProgLime),
                    child: const Icon(Icons.check_rounded, color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plan updated to v$version', style: progBody(15, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('Your next sessions use the new targets.',
                            style: progBody(12, color: kProgMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onUndo,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(color: kProgBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Undo', style: progBody(14, weight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onDone,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        backgroundColor: kProgLime,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Done', style: progBody(14, color: Colors.black, weight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
