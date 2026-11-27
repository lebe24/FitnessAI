import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/energy_analytics.dart';
import 'package:fitness/domain/energy/bot_settings.dart';
import 'package:fitness/ui/features/analytic/views/body/body_actions.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/energy/view_models/bot_settings_controller.dart';
import 'package:fitness/ui/features/energy/view_models/energy_chat_controller.dart';
import 'package:fitness/ui/features/energy/views/bot_mascot.dart';
import 'package:flutter/material.dart';

/// Naming the energy bot and choosing its mascot. Opened from Profile.
class BotSettingsPage extends StatefulWidget {
  final BotSettingsController controller;
  const BotSettingsPage({super.key, required this.controller});

  @override
  State<BotSettingsPage> createState() => _BotSettingsPageState();
}

class _BotSettingsPageState extends State<BotSettingsPage> {
  final _name = TextEditingController();
  BotMascot _mascot = BotMascot.flame;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Analytics.screen('bot_settings');
    widget.controller.loaded.then((_) {
      if (!mounted) return;
      final saved = widget.controller.value;
      setState(() {
        _name.text = saved.name;
        _mascot = saved.mascot;
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  BotSettings get _draft => BotSettings(name: BotSettings.cleanName(_name.text), mascot: _mascot);
  bool get _changed => _loaded && _draft != widget.controller.value;

  Future<void> _save() async {
    if (_saving || !_changed) return;
    setState(() => _saving = true);
    final next = _draft;
    final ok = await widget.controller.save(next);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _name.text = next.name;
    });
    if (ok) {
      const EnergyAnalytics().customised(next);
      FocusScope.of(context).unfocus();
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ok ? kBodyRaised : kBodyRed,
      content: Text(ok ? 'Saved. Say hello to ${next.name}.' : 'Could not save. Try again.',
          style: bodyText(13)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final preview = _draft;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c));

    return BodyPageScaffold(
      title: 'Your bot',
      subtitle: 'Name it and choose how it looks',
      children: [
        BodyCard(
          child: Column(children: [
            BotMascotView(
                mascot: preview.mascot, size: 132, mood: BotMood.greet, semanticLabel: preview.name),
            const SizedBox(height: 8),
            Text(preview.name, textAlign: TextAlign.center, style: bodyHeading(20)),
            const SizedBox(height: 2),
            Text('Your energy bot', style: bodyText(12, color: kBodyMuted)),
          ]),
        ),
        const SizedBox(height: 16),
        BodyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Name'),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                enabled: _loaded,
                maxLength: BotSettings.maxNameLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _save(),
                style: bodyText(15),
                cursorColor: kBodyLime,
                decoration: InputDecoration(
                  hintText: BotSettings.defaultName,
                  hintStyle: bodyText(15, color: kBodyMuted),
                  counterStyle: bodyText(11, color: kBodyMuted),
                  helperText: 'Letters and numbers. Leave empty for ${BotSettings.defaultName}.',
                  helperStyle: bodyText(11, color: kBodyMuted),
                  helperMaxLines: 2,
                  filled: true,
                  fillColor: kBodyBg,
                  enabledBorder: border(kBodyBorder),
                  disabledBorder: border(kBodyBorder),
                  focusedBorder: border(kBodyLime),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BodyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Mascot'),
              const SizedBox(height: 12),
              LayoutBuilder(builder: (_, box) {
                final width = (box.maxWidth - 10) / 2;
                return Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final m in BotMascot.values)
                    SizedBox(
                      width: width,
                      child: _MascotChoice(
                        mascot: m,
                        selected: m == _mascot,
                        onTap: _loaded ? () => setState(() => _mascot = m) : null,
                      ),
                    ),
                ]);
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _changed && !_saving ? _save : null,
            style: FilledButton.styleFrom(
              backgroundColor: kBodyLime,
              foregroundColor: Colors.black,
              disabledBackgroundColor: kBodyChip,
              disabledForegroundColor: kBodyMuted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(_saving ? 'Saving…' : 'Save',
                style: bodyHeading(15, color: _changed && !_saving ? Colors.black : kBodyMuted)),
          ),
        ),
      ],
    );
  }
}

class _MascotChoice extends StatelessWidget {
  final BotMascot mascot;
  final bool selected;
  final VoidCallback? onTap;
  const _MascotChoice({required this.mascot, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: '${mascot.label} mascot',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected ? kBodyLime.withValues(alpha: 0.08) : kBodyBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? kBodyLime : kBodyBorder, width: 1.5),
            ),
            child: Column(children: [
              BotMascotView(mascot: mascot, size: 68, animate: selected),
              const SizedBox(height: 8),
              Text(mascot.label,
                  style: bodyText(12.5,
                      color: selected ? kBodyLime : kBodySoft, weight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}
