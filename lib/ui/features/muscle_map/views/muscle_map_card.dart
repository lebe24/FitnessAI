import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/muscle_map/body_map_source.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:fitness/ui/features/muscle_map/views/body_figure.dart';
import 'package:fitness/ui/features/muscle_map/views/muscle_map_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kCard   = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kLime   = Color(0xFFCCFF00);
const _kDim    = Color(0x80FFFFFF);

/// Home-screen entry to [MuscleMapPage]. Previews the body so the card says
/// what it opens before anyone reads it.
class MuscleMapCard extends StatelessWidget {
  const MuscleMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final locked = !sl<AccessPolicy>().canUse(PremiumFeature.muscleMap);

    return GestureDetector(
      onTap: () => requirePremium(
        context,
        PremiumFeature.muscleMap,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MuscleMapPage()),
        ),
      ),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 110, child: _BodyPreview()),
            Expanded(child: _CardText(locked: locked)),
          ],
        ),
      ),
    );
  }
}

/// Front and back side by side. Loads the shared geometry once; the page
/// reuses the same cached copy.
class _BodyPreview extends StatefulWidget {
  const _BodyPreview();

  @override
  State<_BodyPreview> createState() => _BodyPreviewState();
}

class _BodyPreviewState extends State<_BodyPreview> {
  BodyMap? _map;

  @override
  void initState() {
    super.initState();
    BodyMapSource.load().then((map) {
      if (mounted) setState(() => _map = map);
    }).catchError((_) {
      // The preview is decoration. If the asset cannot load, the card still
      // reads and still opens the page, which shows the real error.
    });
  }

  @override
  Widget build(BuildContext context) {
    final map = _map;
    if (map == null) return const SizedBox.shrink();
    final tint = _kLime.withValues(alpha: 0.55);
    final silhouette = Colors.white.withValues(alpha: 0.10);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: BodyFigure(
              view: map.front,
              muscleColor: tint,
              silhouetteColor: silhouette,
              outlineColor: _kCard,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: BodyFigure(
              view: map.back,
              muscleColor: tint,
              silhouetteColor: silhouette,
              outlineColor: _kCard,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardText extends StatelessWidget {
  final bool locked;
  const _CardText({required this.locked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Train by muscle',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              PremiumBadge(visible: locked),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a muscle to find video tutorials that train it.',
            style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: _kDim),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.accessibility_new_rounded,
                    color: Colors.white.withValues(alpha: 0.6), size: 13),
                const SizedBox(width: 5),
                Text(
                  'Open map',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.6),
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
