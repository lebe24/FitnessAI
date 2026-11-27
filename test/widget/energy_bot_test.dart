import 'package:fitness/data/services/energy/bot_settings_store.dart';
import 'package:fitness/data/services/energy/energy_coach_service.dart';
import 'package:fitness/domain/energy/bot_settings.dart';
import 'package:fitness/domain/energy/energy_session.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:fitness/ui/features/analytic/history_samples.dart';
import 'package:fitness/ui/features/analytic/views/session_detail_page.dart';
import 'package:fitness/ui/features/energy/energy_services.dart';
import 'package:fitness/ui/features/energy/view_models/bot_settings_controller.dart';
import 'package:fitness/ui/features/energy/view_models/energy_chat_controller.dart';
import 'package:fitness/ui/features/energy/views/bot_mascot.dart';
import 'package:fitness/ui/features/energy/views/energy_chat_sheet.dart';
import 'package:fitness/ui/features/energy/views/energy_nudge.dart';
import 'package:fitness/ui/features/energy/views/finished_session.dart';
import 'package:fitness/ui/features/energy/views/workout_complete_dialog.dart';
import 'package:fitness/ui/features/profile/views/bot_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

final _session = HistorySamples.all.first;

class _Fixture {
  bool pro;
  int paywalls = 0;
  final bool buys;
  final BotSettingsController bot;
  _Fixture({
    this.pro = true,
    this.buys = false,
    BotSettings settings = const BotSettings(),
  }) : bot = BotSettingsController(MemoryBotSettingsStore(settings));

  late final services = EnergyServices(
    allowed: () => pro,
    access: ChangeNotifier(),
    unlock: (_) async {
      paywalls++;
      if (buys) pro = true;
      return buys;
    },
    weightKg: () async => 80,
    responder: const LocalEnergyResponder(),
    bot: bot,
  );
}

class _Offline implements EnergyResponder {
  @override
  Future<EnergyReply> reply(EnergyAsk ask) async => EnergyReply.fallback(ask, EnergyError.offline);
}

/// The mascots never stop moving, so time is stepped rather than settled.
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 40; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void _screen(WidgetTester t, [Size size = const Size(390, 844), double keyboard = 0]) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  t.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(t.view.reset);
}

Future<void> _page(WidgetTester t, Widget page) async {
  await t.pumpWidget(MaterialApp(home: page));
  await _settle(t);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('on a session page', () {
    SessionDetailPage page(_Fixture f, {bool open = false}) => SessionDetailPage(
        session: _session, imperial: false, energy: f.services, openEnergy: open);

    testWidgets('the bot peeks in and opens the chat', (t) async {
      _screen(t);
      final f = _Fixture(settings: const BotSettings(name: 'Rex', mascot: BotMascot.robot));
      await _page(t, page(f));

      expect(find.byType(EnergyNudge), findsOneWidget);
      expect(find.byType(PremiumBadge), findsNothing);
      expect(find.bySemanticsLabel('Ask Rex about your energy'), findsOneWidget);
      expect(t.widget<BotMascotView>(find.byType(BotMascotView)).mascot, BotMascot.robot);
      expect(find.text('Share'), findsOneWidget);

      await t.tap(find.text('What did you burn? 🔥'));
      await _settle(t);
      expect(find.byType(EnergyChatSheet), findsOneWidget);
      expect(find.text('Rex'), findsOneWidget);
      expect(find.text('ENERGY USED'), findsOneWidget);
    });

    testWidgets('free members see the lock and the paywall, not the chat', (t) async {
      _screen(t);
      final f = _Fixture(pro: false);
      await _page(t, page(f));

      expect(find.byType(PremiumBadge), findsOneWidget);
      await t.tap(find.text('What did you burn? 🔥'));
      await _settle(t);
      expect(f.paywalls, 1);
      expect(find.byType(EnergyChatSheet), findsNothing);
    });

    testWidgets('buying Pro opens the chat', (t) async {
      _screen(t);
      final f = _Fixture(pro: false, buys: true);
      await _page(t, page(f));
      await t.tap(find.text('What did you burn? 🔥'));
      await _settle(t);
      expect(find.byType(EnergyChatSheet), findsOneWidget);
    });

    testWidgets('opens by itself after a workout', (t) async {
      _screen(t);
      await _page(t, page(_Fixture(), open: true));
      expect(find.byType(EnergyChatSheet), findsOneWidget);
    });

    testWidgets('fits a narrow phone with the share button', (t) async {
      _screen(t, const Size(320, 568));
      await _page(t, page(_Fixture(pro: false)));
      final share = t.getRect(find.byType(FloatingActionButton));
      expect(t.getRect(find.byType(BotMascotView)).overlaps(share), isFalse);
      expect(t.getRect(find.text('What did you burn? 🔥')).overlaps(share), isFalse);
      expect(find.byType(PremiumBadge), findsOneWidget);
    });

    testWidgets('the bubble can be closed and the mascot stays', (t) async {
      _screen(t);
      await _page(t, page(_Fixture()));
      await t.tap(find.byTooltip('Dismiss'));
      await _settle(t);
      expect(find.text('What did you burn? 🔥'), findsNothing);
      expect(find.byType(BotMascotView), findsOneWidget);
    });
  });

  group('chat', () {
    Future<void> open(WidgetTester t, {int? minutes, EnergyResponder? responder}) async {
      final s = EnergySession.of(_session);
      await t.pumpWidget(MaterialApp(
        home: Builder(
          builder: (c) => Scaffold(
            body: TextButton(
              onPressed: () => showEnergyChat(c,
                  facts: EnergyFacts(
                      session: minutes == null
                          ? EnergySession(title: s.title, sets: s.sets)
                          : EnergySession(title: s.title, sets: s.sets, minutes: minutes),
                      weightKg: 80),
                  responder: responder ?? const LocalEnergyResponder()),
              child: const Text('go'),
            ),
          ),
        ),
      ));
      await t.tap(find.text('go'));
      await _settle(t);
    }

    for (final (size, keyboard) in const [
      (Size(320, 568), 260.0),
      (Size(390, 844), 336.0),
      (Size(320, 568), 0.0),
    ]) {
      testWidgets('asks, answers and fits at $size with a keyboard of $keyboard', (t) async {
        _screen(t, size, keyboard);
        await open(t);
        expect(find.text('BeFit Bot'), findsOneWidget);

        await t.enterText(find.byType(TextField), '45');
        await t.testTextInput.receiveAction(TextInputAction.send);
        await _settle(t);
        expect(find.text('210–300', skipOffstage: false), findsOneWidget);

        await t.enterText(find.byType(TextField), 'what is that in food?');
        await t.testTextInput.receiveAction(TextInputAction.send);
        await _settle(t);
        expect(find.textContaining('banana'), findsWidgets);

        await t.tap(find.bySemanticsLabel('Close'));
        await _settle(t);
        expect(find.byType(EnergyChatSheet), findsNothing);
      });
    }

    testWidgets('a suggested question is asked with one tap', (t) async {
      _screen(t);
      await open(t, minutes: 60);
      await t.tap(find.text('How did you work that out?'));
      await _settle(t);
      expect(find.textContaining('activity scale'), findsOneWidget);
      expect(find.textContaining('Quick answer'), findsNothing);
    });

    testWidgets('says when the coach could not be reached', (t) async {
      _screen(t);
      await open(t, minutes: 60, responder: _Offline());
      await t.tap(find.text('How did you work that out?'));
      await _settle(t);
      expect(find.textContaining('Quick answer'), findsOneWidget);
    });
  });

  group('after finishing', () {
    Future<bool?> pop(WidgetTester t, String tap) async {
      bool? answer;
      await t.pumpWidget(MaterialApp(
        home: Builder(
          builder: (c) => TextButton(
            onPressed: () async => answer = await showWorkoutCompleteDialog(c,
                bot: const BotSettings(), exercises: 7, minutes: 58),
            child: const Text('go'),
          ),
        ),
      ));
      await t.tap(find.text('go'));
      await _settle(t);
      expect(find.text('Workout complete!'), findsOneWidget);
      expect(find.text('7 exercises · 58 min'), findsOneWidget);
      await t.tap(find.text(tap));
      await _settle(t);
      return answer;
    }

    testWidgets('the pop-up can be accepted', (t) async {
      _screen(t);
      expect(await pop(t, 'See my energy'), isTrue);
    });

    testWidgets('or put off', (t) async {
      _screen(t, const Size(320, 568));
      expect(await pop(t, 'Not now'), isFalse);
    });

    testWidgets('goes to the session page with the chat open', (t) async {
      _screen(t);
      final f = _Fixture();
      await t.pumpWidget(MaterialApp(
        home: Builder(
          builder: (c) => TextButton(
            onPressed: () => openFinishedSession(c,
                saved: _session,
                sessions: () async => throw Exception('offline'),
                imperial: () async => false,
                energy: f.services),
            child: const Text('go'),
          ),
        ),
      ));
      await t.tap(find.text('go'));
      await _settle(t);
      expect(find.byType(SessionDetailPage), findsOneWidget);
      expect(find.byType(EnergyChatSheet), findsOneWidget);
    });
  });

  group('bot settings', () {
    testWidgets('renames the bot and changes its mascot', (t) async {
      _screen(t, const Size(390, 1200));
      final f = _Fixture();
      await _page(t, BotSettingsPage(controller: f.bot));

      FilledButton save() => t.widget<FilledButton>(find.byType(FilledButton));
      expect(save().onPressed, isNull); // nothing changed yet

      await t.enterText(find.byType(TextField), 'Coach Mo');
      await t.tap(find.text('Kettlebell'));
      await _settle(t);
      await t.tap(find.text('Save'));
      await _settle(t);

      expect(f.bot.value, const BotSettings(name: 'Coach Mo', mascot: BotMascot.kettlebell));
      expect(save().onPressed, isNull);
      expect(find.textContaining('Say hello to Coach Mo'), findsOneWidget);
    });

    testWidgets('an empty name goes back to the default', (t) async {
      _screen(t, const Size(390, 1200));
      final f = _Fixture(settings: const BotSettings(name: 'Rex'));
      await _page(t, BotSettingsPage(controller: f.bot));
      await t.enterText(find.byType(TextField), '   ');
      await t.pump();
      await t.tap(find.text('Save'));
      await _settle(t);
      expect(f.bot.value.name, 'BeFit Bot');
    });

    testWidgets('offers every mascot and fits a narrow phone', (t) async {
      _screen(t, const Size(320, 1300));
      await _page(t, BotSettingsPage(controller: _Fixture().bot));
      for (final m in BotMascot.values) {
        expect(find.text(m.label), findsOneWidget);
      }
    });
  });
}
