import 'package:fitness/domain/progression/progression_proposal.dart';
import 'package:fitness/ui/features/progression/views/progression_theme.dart';
import 'package:flutter/material.dart';

/// Every update applied to the plan, newest first, with a way back for the
/// latest one.
class ProgressionHistoryPage extends StatefulWidget {
  final List<AppliedUpdate> updates;

  /// Reverts the latest update and returns whether it worked. Without it the
  /// page only previews the undo.
  final Future<bool> Function()? onUndo;
  final VoidCallback? onSettings;

  const ProgressionHistoryPage({
    super.key,
    required this.updates,
    this.onUndo,
    this.onSettings,
  });

  @override
  State<ProgressionHistoryPage> createState() => _ProgressionHistoryPageState();
}

class _ProgressionHistoryPageState extends State<ProgressionHistoryPage> {
  late List<AppliedUpdate> _updates = List.of(widget.updates);

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  String _date(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  Future<void> _confirmUndo() async {
    final latest = _updates.first;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UndoSheet(update: latest),
    );
    if (ok != true || !mounted) return;
    final done = widget.onUndo == null ? true : await widget.onUndo!();
    if (done && mounted) setState(() => _updates = _updates.sublist(1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kProgBg,
      body: Column(
        children: [
          Container(
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
                          Text('Update history', style: progHeading(20)),
                          const SizedBox(height: 2),
                          Text('Every change made to your plan', style: progBody(12, color: kProgMuted)),
                        ],
                      ),
                    ),
                    if (widget.onSettings != null)
                      Semantics(
                        button: true,
                        label: 'Update settings',
                        child: GestureDetector(
                          onTap: widget.onSettings,
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
          ),
          Expanded(
            child: _updates.isEmpty
                ? Center(child: Text('No updates yet', style: progBody(14, color: kProgMuted)))
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    itemCount: _updates.length,
                    itemBuilder: (_, i) => _TimelineRow(
                      update: _updates[i],
                      date: _date(_updates[i].date),
                      isFirst: i == 0,
                      isLast: i == _updates.length - 1,
                      onUndo: i == 0 ? _confirmUndo : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final AppliedUpdate update;
  final String date;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onUndo;

  const _TimelineRow({
    required this.update,
    required this.date,
    required this.isFirst,
    required this.isLast,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final accent = update.isDeload ? kProgAmber : kProgLime;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst ? accent : kProgBg,
                    border: Border.all(color: accent, width: 2),
                  ),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: kProgBorder)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kProgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kProgBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Version ${update.version}', style: progBody(15, weight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        if (isFirst)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: kProgLime.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('CURRENT',
                                style: progBody(9.5, color: kProgLime, weight: FontWeight.w800)
                                    .copyWith(letterSpacing: 0.7)),
                          ),
                        const Spacer(),
                        Text(date, style: progBody(12, color: kProgMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${update.changeCount} changes · ${update.wasAutomatic ? 'applied automatically' : 'you reviewed'}',
                      style: progBody(12, color: kProgMuted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final h in update.highlights)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(h, style: progBody(11.5, color: accent, weight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    if (onUndo != null) ...[
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: onUndo,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.undo_rounded, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('Undo this update', style: progBody(12.5, weight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UndoSheet extends StatelessWidget {
  final AppliedUpdate update;
  const _UndoSheet({required this.update});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kProgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: kProgBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Undo version ${update.version}?', style: progHeading(18)),
              const SizedBox(height: 8),
              Text(
                'Your plan goes back to version ${update.version - 1}. Weights and reps '
                'you have already logged stay in your history.',
                style: progBody(13, color: kProgMuted, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Undo update', style: progBody(15, color: Colors.black, weight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Keep it', style: progBody(13, color: kProgMuted, weight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
