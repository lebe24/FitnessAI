import 'package:fitness/domain/progression/progression_proposal.dart';
import 'package:fitness/ui/features/progression/views/progression_theme.dart';
import 'package:flutter/material.dart';

/// The card on the programs screen that says where the plan's next update
/// stands, and opens it.
class ProgressionEntryCard extends StatelessWidget {
  final ProgressionStatus status;

  /// Changes waiting, for [ProgressionStatus.ready].
  final int readyCount;

  /// Sessions still to log before the next update, for
  /// [ProgressionStatus.building], and how many it takes in all.
  final int sessionsLeft;
  final int sessionsNeeded;

  /// When the last update was applied, for [ProgressionStatus.upToDate].
  final String lastUpdated;
  final VoidCallback onTap;

  const ProgressionEntryCard({
    super.key,
    required this.status,
    this.readyCount = 0,
    this.sessionsLeft = 0,
    this.sessionsNeeded = 6,
    this.lastUpdated = '',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ready = status == ProgressionStatus.ready;
    final off = status == ProgressionStatus.off;

    final (title, body, cta) = switch (status) {
      ProgressionStatus.ready => (
          '$readyCount updates ready',
          'Your last 4 weeks show where to add weight, reps or sets.',
          'Review update',
        ),
      ProgressionStatus.building => (
          'Learning your training',
          sessionsLeft == 1
              ? 'Log 1 more session and your plan can start progressing.'
              : 'Log $sessionsLeft more sessions and your plan can start progressing.',
          'See how it works',
        ),
      ProgressionStatus.upToDate => (
          'Plan is up to date',
          'Last updated $lastUpdated. The next check is in 5 days.',
          'View history',
        ),
      ProgressionStatus.off => (
          'Smart updates are off',
          'Turn them on and your plan will adjust to the weights you lift.',
          'Turn on',
        ),
    };

    return Semantics(
      button: true,
      label: '$title. $body',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ready ? kProgLime.withValues(alpha: 0.35) : kProgBorder),
            gradient: ready
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kProgLime.withValues(alpha: 0.12), kProgCard],
                  )
                : null,
            color: ready ? null : kProgCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: (ready ? kProgLime : Colors.white).withValues(alpha: ready ? 0.16 : 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      off ? Icons.auto_awesome_outlined : Icons.auto_awesome_rounded,
                      size: 19,
                      color: ready ? kProgLime : (off ? kProgMuted : Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: progHeading(16))),
                  if (ready) const _NewDot(),
                ],
              ),
              const SizedBox(height: 10),
              Text(body, style: progBody(12.5, color: kProgMuted, height: 1.45)),
              if (status == ProgressionStatus.building) ...[
                const SizedBox(height: 14),
                _Progress(done: sessionsNeeded - sessionsLeft, of: sessionsNeeded),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(cta,
                      style: progBody(13, color: ready ? kProgLime : Colors.white, weight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 15, color: ready ? kProgLime : Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewDot extends StatelessWidget {
  const _NewDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: kProgLime, borderRadius: BorderRadius.circular(8)),
      child: Text('NEW', style: progBody(10, color: Colors.black, weight: FontWeight.w800).copyWith(letterSpacing: 0.8)),
    );
  }
}

class _Progress extends StatelessWidget {
  final int done;
  final int of;
  const _Progress({required this.done, required this.of});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < of; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i < done ? kProgLime : kProgRaised,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
        const SizedBox(width: 12),
        Text('$done/$of', style: progBody(11.5, color: kProgMuted, weight: FontWeight.w700)),
      ],
    );
  }
}
