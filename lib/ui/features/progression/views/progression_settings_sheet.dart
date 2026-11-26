import 'package:fitness/domain/progression/progression_proposal.dart';
import 'package:fitness/ui/features/progression/views/progression_theme.dart';
import 'package:flutter/material.dart';

Future<void> showProgressionSettings(
  BuildContext context, {
  ProgressionSettings initial = const ProgressionSettings(),
  Future<void> Function(ProgressionSettings settings)? onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProgressionSettingsSheet(initial: initial, onSave: onSave),
  );
}

/// How the plan updates itself: on or off, how it is applied, how often, and
/// how hard it pushes.
class ProgressionSettingsSheet extends StatefulWidget {
  final ProgressionSettings initial;
  final Future<void> Function(ProgressionSettings settings)? onSave;
  const ProgressionSettingsSheet({
    super.key,
    this.initial = const ProgressionSettings(),
    this.onSave,
  });

  @override
  State<ProgressionSettingsSheet> createState() => _ProgressionSettingsSheetState();
}

class _ProgressionSettingsSheetState extends State<ProgressionSettingsSheet> {
  late bool _on = widget.initial.enabled;
  late ApplyMode _mode = widget.initial.mode;
  late ProgressionCadence _cadence = widget.initial.cadence;
  late ProgressionPace _pace = widget.initial.pace;
  late bool _deloads = widget.initial.deloads;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave?.call(ProgressionSettings(
      enabled: _on,
      mode: _mode,
      cadence: _cadence,
      pace: _pace,
      deloads: _deloads,
    ));
    if (mounted) Navigator.of(context).maybePop();
  }

  static const _paceText = {
    ProgressionPace.steady: 'Small jumps and extra reps first. Best if you are returning or recovering.',
    ProgressionPace.balanced: 'Adds load once you earn it. Right for most people.',
    ProgressionPace.ambitious: 'Moves up as soon as you hit the top of a range. Needs good sleep and food.',
  };

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.92;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: kProgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: kProgBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Smart updates', style: progHeading(20)),
              const SizedBox(height: 4),
              Text('Let your plan keep up with your training.',
                  style: progBody(13, color: kProgMuted)),
              const SizedBox(height: 18),
              _SwitchTile(
                title: 'Update my plan automatically',
                subtitle: 'Uses your logged sets and your goal.',
                value: _on,
                onChanged: (v) => setState(() => _on = v),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _on ? 1 : 0.4,
                child: IgnorePointer(
                  ignoring: !_on,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('When an update is ready'),
                      _Segmented<ApplyMode>(
                        value: _mode,
                        options: const {
                          ApplyMode.review: 'Let me review',
                          ApplyMode.automatic: 'Apply it',
                        },
                        onChanged: (v) => setState(() => _mode = v),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _mode == ApplyMode.review
                            ? 'You see every change and choose which to keep.'
                            : 'Changes are applied for you. You can undo from History.',
                        style: progBody(12, color: kProgMuted, height: 1.4),
                      ),
                      const _Label('Look at my training'),
                      _Segmented<ProgressionCadence>(
                        value: _cadence,
                        options: const {
                          ProgressionCadence.weekly: 'Weekly',
                          ProgressionCadence.fortnightly: 'Every 2 weeks',
                          ProgressionCadence.monthly: 'Monthly',
                        },
                        onChanged: (v) => setState(() => _cadence = v),
                      ),
                      const _Label('How hard to push'),
                      _Segmented<ProgressionPace>(
                        value: _pace,
                        options: const {
                          ProgressionPace.steady: 'Steady',
                          ProgressionPace.balanced: 'Balanced',
                          ProgressionPace.ambitious: 'Ambitious',
                        },
                        onChanged: (v) => setState(() => _pace = v),
                      ),
                      const SizedBox(height: 8),
                      Text(_paceText[_pace]!, style: progBody(12, color: kProgMuted, height: 1.4)),
                      const SizedBox(height: 18),
                      const Divider(height: 1, color: kProgBorder),
                      _SwitchTile(
                        title: 'Plan easy weeks',
                        subtitle: 'A lighter week after about 6 weeks of hard training.',
                        value: _deloads,
                        onChanged: (v) => setState(() => _deloads = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kProgRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: kProgMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Updates only change sets, reps and weight. Your exercises and '
                        'training days stay as they are.',
                        style: progBody(11.5, color: kProgMuted, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: kProgLime,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Save', style: progBody(15, color: Colors.black, weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(text, style: progBody(13, weight: FontWeight.w700)),
      );
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: progBody(14, weight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(subtitle, style: progBody(12, color: kProgMuted, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.black,
            activeTrackColor: kProgLime,
            inactiveThumbColor: kProgMuted,
            inactiveTrackColor: kProgRaised,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  const _Segmented({required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kProgBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kProgBorder),
      ),
      child: Row(
        children: [
          for (final e in options.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: e.key == value,
                label: e.value,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: e.key == value ? kProgLime : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      e.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: progBody(
                        12.5,
                        color: e.key == value ? Colors.black : kProgMuted,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
