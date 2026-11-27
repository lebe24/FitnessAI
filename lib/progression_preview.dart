// Design-review entry point for the plan-update screens. Not part of the app:
// it shows the screens with sample data and nothing behind them.
//
//   flutter run -t lib/progression_preview.dart -d <device>
//
// On web, open a screen directly with ?screen=review|deload|history|settings.
import 'package:fitness/domain/progression/progression_proposal.dart';
import 'package:fitness/ui/features/progression/progression_samples.dart';
import 'package:fitness/ui/features/progression/views/progression_entry_card.dart';
import 'package:fitness/ui/features/progression/views/progression_history_page.dart';
import 'package:fitness/ui/features/progression/views/progression_review_page.dart';
import 'package:fitness/ui/features/progression/views/progression_settings_sheet.dart';
import 'package:fitness/ui/features/progression/views/progression_theme.dart';
import 'package:flutter/material.dart';

void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: kProgBg),
      // Keep a phone-width column when opened in a wide browser window.
      builder: (context, child) => ColoredBox(
        color: kProgBg,
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 390), child: child),
        ),
      ),
      home: const _ProgramsMock(),
    );
  }
}

/// Stands in for the My Programs screen, with the entry card in each state.
class _ProgramsMock extends StatefulWidget {
  const _ProgramsMock();

  @override
  State<_ProgramsMock> createState() => _ProgramsMockState();
}

class _ProgramsMockState extends State<_ProgramsMock> {
  @override
  void initState() {
    super.initState();
    final screen = Uri.base.queryParameters['screen'];
    if (screen == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (screen) {
        case 'review':
          _push(const ProgressionReviewPage(proposal: ProgressionSamples.ready));
        case 'deload':
          _push(const ProgressionReviewPage(proposal: ProgressionSamples.deload));
        case 'history':
          _push(ProgressionHistoryPage(updates: ProgressionSamples.history));
        case 'settings':
          showProgressionSettings(context);
      }
    });
  }

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    void review() => _push(const ProgressionReviewPage(proposal: ProgressionSamples.ready));
    void history() => _push(ProgressionHistoryPage(updates: ProgressionSamples.history));

    return Scaffold(
      backgroundColor: kProgBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('My Programs', style: progHeading(22)),
            const SizedBox(height: 4),
            Text('Design review · entry card states', style: progBody(12, color: kProgMuted)),
            const SizedBox(height: 20),
            _Tag('Ready'),
            ProgressionEntryCard(status: ProgressionStatus.ready, readyCount: 8, onTap: review),
            const SizedBox(height: 20),
            _Tag('Not enough history yet'),
            ProgressionEntryCard(
                status: ProgressionStatus.building, sessionsLeft: 2, sessionsNeeded: 6, onTap: () {}),
            const SizedBox(height: 20),
            _Tag('Up to date'),
            ProgressionEntryCard(
                status: ProgressionStatus.upToDate, lastUpdated: 'Nov 17', onTap: history),
            const SizedBox(height: 20),
            _Tag('Turned off'),
            ProgressionEntryCard(
                status: ProgressionStatus.off, onTap: () => showProgressionSettings(context)),
            const SizedBox(height: 28),
            _Tag('Other screens'),
            _Link('Review an easy week (deload)',
                () => _push(const ProgressionReviewPage(proposal: ProgressionSamples.deload))),
            _Link('Update history', history),
            _Link('Settings', () => showProgressionSettings(context)),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: progBody(10.5, color: kProgMuted, weight: FontWeight.w700).copyWith(letterSpacing: 1)),
      );
}

class _Link extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _Link(this.text, this.onTap);

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(text, style: progBody(14, weight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded, color: kProgMuted),
        onTap: onTap,
      );
}
