import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/ui/features/analytic/views/body/body_actions.dart';
import 'package:fitness/ui/features/analytic/views/body/muscle_development_card.dart';
import 'package:fitness/ui/features/analytic/views/body/physique_scores_card.dart';
import 'package:flutter/material.dart';

/// Which muscles are strong and which need work: the development map, the
/// strengths and focus areas, and the latest physique scan. Opened from the
/// Muscles trained card on the Analytics tab.
class MuscleDevelopmentPage extends StatefulWidget {
  const MuscleDevelopmentPage({super.key});

  @override
  State<MuscleDevelopmentPage> createState() => _MuscleDevelopmentPageState();
}

class _MuscleDevelopmentPageState extends State<MuscleDevelopmentPage> with BodyActions<MuscleDevelopmentPage> {
  @override
  void initState() {
    super.initState();
    Analytics.screen('muscle_development');
    startBodyActions();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final hasMore = vm.strengths.isNotEmpty || vm.focusAreas.isNotEmpty;
        return BodyPageScaffold(
          title: 'Muscle development',
          subtitle: 'Strong, average and focus muscles',
          children: [
            if (vm.offline) const OfflineNote(),
            MuscleDevelopmentCard(
              muscles: vm.muscles,
              loading: vm.loading,
              onSelect: openMuscle,
            ),
            const SizedBox(height: 16),
            StrengthsFocusCard(
              strengths: vm.strengths,
              focusAreas: vm.focusAreas,
              onSelect: openMuscle,
            ),
            if (hasMore) const SizedBox(height: 16),
            PhysiqueScoresCard(scan: vm.scan),
          ],
        );
      },
    );
  }
}
