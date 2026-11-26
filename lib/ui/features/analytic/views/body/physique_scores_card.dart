import 'package:fitness/domain/body/scan_summary.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:flutter/material.dart';

/// The four physique scores from the latest body scan.
class PhysiqueScoresCard extends StatelessWidget {
  final ScanSummary? scan;
  const PhysiqueScoresCard({super.key, required this.scan});

  @override
  Widget build(BuildContext context) {
    final s = scan;
    if (s == null) {
      return BodyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Physique Scores', style: bodyHeading(16)),
            const SizedBox(height: 10),
            Text(
              'Scan your physique from the Home tab and your aesthetics, muscle development, '
              'conditioning and posture scores appear here, and feed your muscle map.',
              style: bodyText(12.5, color: kBodyMuted, height: 1.5),
            ),
          ],
        ),
      );
    }

    final rows = [
      ('Aesthetics', s.aesthetics),
      ('Muscle Dev', s.muscleDevelopment),
      ('Conditioning', s.conditioning),
      ('Posture', s.posture),
    ];
    final best = rows.map((r) => r.$2).reduce((a, b) => a > b ? a : b);

    return BodyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('Physique Scores', subtitle: 'Scanned ${shortDate(s.scannedAt)}'),
          const SizedBox(height: 16),
          for (final (label, score) in rows) ...[
            Row(
              children: [
                Expanded(child: Text(label, style: bodyText(12.5, weight: FontWeight.w600))),
                Text('$score',
                    style: bodyHeading(14, color: score == best ? kBodyLime : const Color(0xFFC9CCD3))),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: kBodyUntrained,
                color: score == best ? kBodyLime : const Color(0xFF7A9400),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              _Chip('Body fat ${s.bodyFatPct.toStringAsFixed(s.bodyFatPct == s.bodyFatPct.roundToDouble() ? 0 : 1)}%'),
              const SizedBox(width: 8),
              _Chip('Muscle ${s.muscleMassPct.toStringAsFixed(s.muscleMassPct == s.muscleMassPct.roundToDouble() ? 0 : 1)}%'),
            ],
          ),
          const SizedBox(height: 10),
          Text('Scan again from the Home tab to update these.', style: bodyText(11.5, color: kBodyMuted)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBodyBorder),
        ),
        child: Text(text, style: bodyText(12, weight: FontWeight.w600)),
      );
}
