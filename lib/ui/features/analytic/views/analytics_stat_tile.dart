import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:flutter/material.dart';

/// One of the three small figures at the top of Analytics: streak, workouts and
/// total time.
class AnalyticsStatTile extends StatelessWidget {
  final IconData icon;
  final Color color;

  /// Null while loading.
  final String? value;
  final String label;
  final String sub;

  const AnalyticsStatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: kBodyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 12),
          if (value == null)
            Container(
              height: 24,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(6),
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value!, style: bodyHeading(20)),
            ),
          const SizedBox(height: 4),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bodyText(12, color: Colors.white.withValues(alpha: 0.8), weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bodyText(10, color: Colors.white.withValues(alpha: 0.5), weight: FontWeight.w400)),
        ],
      ),
    );
  }
}
