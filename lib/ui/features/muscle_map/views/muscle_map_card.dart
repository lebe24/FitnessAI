import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_events.dart';
import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/muscle_map/body_map_source.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:fitness/ui/features/muscle_map/views/body_figure.dart';
import 'package:fitness/ui/features/muscle_map/views/muscle_map_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kCard    = Color(0xFF111318);
const _kRaised  = Color(0xFF171A22);
const _kBorder  = Color(0xFF1E2330);
const _kLime    = Color(0xFFCCFF00);
const _kMuted   = Color(0xFF8C909B);
const _kMuscle  = Color(0xFF232837);
const _kFigure  = Color(0xFF1B2030);

/// The muscles lit on the card. The card is a preview of the map, not a
/// readout of the user's training, so the same upper-body groups are lit for
/// everyone and the real numbers live on the page it opens.
const _kLit = {'chest', 'deltoids', 'abs'};

/// Home-screen entry to [MuscleMapPage]. Previews the body so the card says
/// what it opens before anyone reads it.
class MuscleMapCard extends StatelessWidget {
  const MuscleMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final locked = !sl<AccessPolicy>().canUse(PremiumFeature.muscleMap);

    return MuscleMapCardView(
      locked: locked,
      onTap: () {
        Analytics.track(AnalyticsEvents.homeCardTapped, {
          'card': 'muscle_map',
          'locked': locked,
        });
        requirePremium(
          context,
          PremiumFeature.muscleMap,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MuscleMapPage()),
          ),
        );
      },
    );
  }
}

/// The card itself, with no app services behind it, so it can be shown and
/// tested on its own.
class MuscleMapCardView extends StatelessWidget {
  final bool locked;
  final VoidCallback onTap;
  const MuscleMapCardView({super.key, required this.locked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Muscle Map. See which muscles you train most.',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 160,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBorder),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 12,
                bottom: 12,
                right: 22,
                width: 84,
                child: const _BodyPreview(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 124, 18),
                child: _CardText(locked: locked),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The front of the body with the upper-body muscles lit. Loads the shared
/// geometry once; the page reuses the same cached copy.
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
    BodyMapSource.load()
        .then((map) {
          if (mounted) setState(() => _map = map);
        })
        .catchError((_) {
          // The preview is decoration. If the asset cannot load, the card still
          // reads and still opens the page, which shows the real error.
        });
  }

  @override
  Widget build(BuildContext context) {
    final map = _map;
    if (map == null) return const SizedBox.shrink();
    return BodyFigure(
      view: map.front,
      muscleColor: _kMuscle,
      silhouetteColor: _kFigure,
      outlineColor: _kCard,
      fillFor: (slug) => _kLit.contains(slug) ? _kLime : null,
    );
  }
}

class _CardText extends StatelessWidget {
  final bool locked;
  const _CardText({required this.locked});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Muscle Map',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PremiumBadge(visible: locked),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'See which muscles you train most and which need attention.',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: _kMuted),
        ),
        const Spacer(),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _kRaised,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.track_changes_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Open map',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
