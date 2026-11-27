// Design-review entry point for the energy bot. Not part of the app: it uses a
// sample session, a sample body weight and the app's offline answers.
//
//   flutter run -t lib/energy_preview.dart -d <device>
//
// On web: ?screen=nudge|locked|chat|ask|noduration|finished|settings
// and &mascot=flame|robot|droplet|kettlebell
import 'package:fitness/data/services/energy/bot_settings_store.dart';
import 'package:fitness/data/services/energy/energy_coach_service.dart';
import 'package:fitness/domain/energy/bot_settings.dart';
import 'package:fitness/domain/energy/energy_session.dart';
import 'package:fitness/ui/features/analytic/history_samples.dart';
import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:fitness/ui/features/analytic/views/session_detail_page.dart';
import 'package:fitness/ui/features/energy/energy_services.dart';
import 'package:fitness/ui/features/energy/view_models/bot_settings_controller.dart';
import 'package:fitness/ui/features/energy/view_models/energy_chat_controller.dart';
import 'package:fitness/ui/features/energy/views/energy_chat_sheet.dart';
import 'package:fitness/ui/features/energy/views/workout_complete_dialog.dart';
import 'package:fitness/ui/features/profile/views/bot_settings_page.dart';
import 'package:flutter/material.dart';

void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: kBodyBg),
        builder: (context, child) => ColoredBox(
          color: Colors.black,
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 390), child: child)),
        ),
        home: _Demo(
          screen: Uri.base.queryParameters['screen'] ?? 'nudge',
          mascot: BotMascot.values.asNameMap()[Uri.base.queryParameters['mascot']] ?? BotMascot.flame,
        ),
      );
}

class _Demo extends StatefulWidget {
  final String screen;
  final BotMascot mascot;
  const _Demo({required this.screen, required this.mascot});

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  final _session = HistorySamples.all.first;
  late final _bot = BotSettingsController(MemoryBotSettingsStore(BotSettings(mascot: widget.mascot)));
  late final _energy = EnergyServices(
    allowed: () => widget.screen != 'locked',
    access: ChangeNotifier(),
    unlock: (_) async => false,
    weightKg: () async => 80,
    responder: const LocalEnergyResponder(),
    bot: _bot,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bot.loaded;
      if (!mounted) return;
      if (widget.screen == 'finished') {
        showWorkoutCompleteDialog(context, bot: _bot.value, exercises: 7, minutes: 58);
        return;
      }
      if (!const ['chat', 'ask', 'noduration'].contains(widget.screen)) return;
      final s = EnergySession.of(_session);
      showEnergyChat(
        context,
        facts: EnergyFacts(
          session: widget.screen != 'noduration'
              ? s
              : EnergySession(title: s.title, sets: s.sets, bigLiftSets: s.bigLiftSets),
          weightKg: 80,
        ),
        responder: _energy.responder,
        bot: _bot.value,
        ask: widget.screen == 'ask'
            ? const ['How did you work that out?', 'What\'s that in food?']
            : const [],
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.screen == 'settings'
      ? BotSettingsPage(controller: _bot)
      : SessionDetailPage(session: _session, imperial: false, energy: _energy);
}
