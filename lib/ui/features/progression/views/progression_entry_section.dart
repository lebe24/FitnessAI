import 'package:fitness/domain/progression/progression_proposal.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/fitness/view_models/fitness_view_model.dart';
import 'package:fitness/ui/features/progression/view_models/progression_view_model.dart';
import 'package:fitness/ui/features/progression/views/progression_entry_card.dart';
import 'package:fitness/ui/features/progression/views/progression_history_page.dart';
import 'package:fitness/ui/features/progression/views/progression_review_page.dart';
import 'package:fitness/ui/features/progression/views/progression_settings_sheet.dart';
import 'package:fitness/ui/features/progression/views/progression_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The smart-update card wired to the real plan and history. Needs a
/// [FitnessViewModel] above it for the active plan.
///
/// [onlyWhenReady] hides it unless an update is waiting, for places like the
/// home screen where an "up to date" card would be noise.
class ProgressionEntrySection extends StatefulWidget {
  final bool onlyWhenReady;
  const ProgressionEntrySection({super.key, this.onlyWhenReady = false});

  @override
  State<ProgressionEntrySection> createState() => _ProgressionEntrySectionState();
}

class _ProgressionEntrySectionState extends State<ProgressionEntrySection> {
  final _vm = sl<ProgressionViewModel>();

  /// The plan the card was last worked out for, so a change to it (another
  /// program made active, or an edit) triggers a fresh look.
  String? _seen;

  String _key(FitnessViewModel f) {
    final p = f.activePlan;
    return p == null ? 'none' : '${p.id}@${p.updatedAt.toIso8601String()}';
  }

  void _refreshIfNeeded(FitnessViewModel fitness) {
    final key = _key(fitness);
    if (key == _seen) return;
    _seen = key;
    // After the frame: this runs from build, and refresh notifies listeners.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _vm.refresh(plan: fitness.activePlan);
      // An automatic update changed the saved plan behind the calendar's back.
      if (_vm.takeAutoApplied()) {
        await fitness.loadFitnessPlans();
        _seen = _key(fitness);
      }
    });
  }

  Future<void> _reload(FitnessViewModel fitness) async {
    await fitness.loadFitnessPlans();
    _seen = _key(fitness);
    await _vm.refresh(plan: fitness.activePlan);
  }

  void _openSettings(BuildContext context, FitnessViewModel fitness) {
    showProgressionSettings(
      context,
      initial: _vm.settings,
      onSave: (s) async {
        await _vm.saveSettings(s);
        await _reload(fitness);
      },
    );
  }

  void _open(BuildContext context, FitnessViewModel fitness) {
    switch (_vm.status) {
      case ProgressionStatus.ready:
        final proposal = _vm.proposal;
        if (proposal == null) return;
        // The coach's review arrives after the page opens, so the page follows
        // the view model. Once the update is applied the view model has none,
        // and the last one shown stays up for the confirmation.
        var shown = proposal;
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (ctx) => ListenableBuilder(
            listenable: _vm,
            builder: (_, __) {
              shown = _vm.proposal ?? shown;
              return ProgressionReviewPage(
                proposal: shown,
                onApply: (skipped) async {
                  final ok = await _vm.apply(skipped: skipped);
                  if (ok) await fitness.loadFitnessPlans();
                  return ok;
                },
                onUndo: () async {
                  final ok = await _vm.undo();
                  if (ok) await _reload(fitness);
                  return ok;
                },
                onDismiss: _vm.dismiss,
                onSettings: () => _openSettings(ctx, fitness),
              );
            },
          ),
        ));
      case ProgressionStatus.building:
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _HowItWorksSheet(sessionsLeft: _vm.sessionsLeft),
        );
      case ProgressionStatus.upToDate:
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (ctx) => ProgressionHistoryPage(
            updates: _vm.updates,
            onUndo: () async {
              final ok = await _vm.undo();
              if (ok) await _reload(fitness);
              return ok;
            },
            onSettings: () => _openSettings(ctx, fitness),
          ),
        ));
      case ProgressionStatus.off:
        _openSettings(context, fitness);
    }
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessViewModel>();
    _refreshIfNeeded(fitness);

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (!_vm.visible) return const SizedBox.shrink();
        if (widget.onlyWhenReady && _vm.status != ProgressionStatus.ready) {
          return const SizedBox.shrink();
        }
        final updated = _vm.lastUpdated;
        return ProgressionEntryCard(
          status: _vm.status,
          readyCount: _vm.readyCount,
          sessionsLeft: _vm.sessionsLeft,
          sessionsNeeded: _vm.sessionsNeeded,
          lastUpdated: updated == null ? 'never' : '${_months[updated.month - 1]} ${updated.day}',
          onTap: () => _open(context, fitness),
        );
      },
    );
  }
}

class _HowItWorksSheet extends StatelessWidget {
  final int sessionsLeft;
  const _HowItWorksSheet({required this.sessionsLeft});

  static const _rules = [
    ('Heavier', 'Every set hit the top of the rep range in 2 sessions in a row.'),
    ('More reps', 'A single rep target moves up by one before the weight does.'),
    ('More volume', 'A comfortable isolation lift gains a set when you are building muscle.'),
    ('Recovery', 'Progress stalled for 3 sessions, or it has been 6 weeks of hard training.'),
    ('Hold', 'A set was missed last time. Repeat it before moving on.'),
  ];

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
              Text('How smart updates work', style: progHeading(18)),
              const SizedBox(height: 8),
              Text(
                'Log your sets with weights. ${sessionsLeft == 1 ? 'One more session' : '$sessionsLeft more sessions'} '
                'and your plan can start adjusting to what you lift, aimed at your goal.',
                style: progBody(13, color: kProgMuted, height: 1.5),
              ),
              const SizedBox(height: 16),
              for (final (title, body) in _rules)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(title, style: progBody(12.5, weight: FontWeight.w700, color: kProgLime)),
                      ),
                      Expanded(child: Text(body, style: progBody(12.5, color: kProgMuted, height: 1.4))),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: kProgLime,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Got it', style: progBody(15, color: Colors.black, weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
