import 'dart:async';

import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/billing/complimentary_access.dart';
import 'package:fitness/data/services/billing/paywall_service.dart';
import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:fitness/domain/models/exercise_history.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/core/widgets/premium_gate.dart';
import 'package:fitness/ui/features/fitness/views/exercise_history_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Subs extends SubscriptionService {
  bool pro = false;
  void setPro(bool v) {
    pro = v;
    notifyListeners();
  }

  @override
  bool get isPro => pro;
}

class _NoComp extends ComplimentaryAccess {
  _NoComp();
  @override
  bool get isGranted => false;
}

/// A paywall that answers from a script: what it reports, and whether the user
/// actually ends up with Pro.
class _Paywall extends PaywallService {
  final _Subs subs;
  bool reportsPurchased = false;
  bool grantsPro = false;
  final shown = <String>[];

  _Paywall(this.subs) : super(subs);

  @override
  Future<bool> present({String? offeringIdentifier, String source = 'unknown'}) async {
    shown.add(source);
    if (grantsPro) subs.setPro(true);
    return reportsPurchased;
  }
}

void main() {
  late _Subs subs;
  late _Paywall paywall;

  setUp(() async {
    subs = _Subs();
    paywall = _Paywall(subs);
    await sl.reset();
    sl.registerSingleton<AccessPolicy>(AccessPolicy(subs, _NoComp()));
    sl.registerSingleton<PaywallService>(paywall);
  });
  tearDown(() async => sl.reset());

  Future<BuildContext> pump(WidgetTester t, Widget child) async {
    late BuildContext ctx;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (c) {
          ctx = c;
          return child;
        }),
      ),
    ));
    return ctx;
  }

  group('requirePremium', () {
    testWidgets('a subscriber goes straight in, with no paywall', (t) async {
      subs.pro = true;
      final ctx = await pump(t, const SizedBox());
      var granted = 0;
      await requirePremium(ctx, PremiumFeature.exerciseHistory, () => granted++);
      expect(granted, 1);
      expect(paywall.shown, isEmpty);
    });

    testWidgets('a free user sees the paywall, and closing it gives nothing', (t) async {
      final ctx = await pump(t, const SizedBox());
      var granted = 0;
      await requirePremium(ctx, PremiumFeature.videoTutorial, () => granted++);
      expect(paywall.shown, ['videoTutorial']);
      expect(granted, 0);
    });

    testWidgets('a paywall that CLAIMS a purchase does not open the feature unless Pro is real',
        (t) async {
      paywall.reportsPurchased = true; // says "purchased", but no entitlement
      final ctx = await pump(t, const SizedBox());
      var granted = 0;
      await requirePremium(ctx, PremiumFeature.videoTutorial, () => granted++);
      expect(granted, 0, reason: 'access is checked, not just the paywall\'s answer');
    });

    testWidgets('a real purchase opens it straight away', (t) async {
      paywall
        ..reportsPurchased = true
        ..grantsPro = true;
      final ctx = await pump(t, const SizedBox());
      var granted = 0;
      await requirePremium(ctx, PremiumFeature.addExercise, () => granted++);
      expect(granted, 1);
    });

    testWidgets('each new feature is behind the same gate', (t) async {
      final ctx = await pump(t, const SizedBox());
      for (final f in [
        PremiumFeature.exerciseVideos,
        PremiumFeature.exerciseHistory,
        PremiumFeature.addExercise,
        PremiumFeature.videoTutorial,
        PremiumFeature.formAnalysis,
      ]) {
        var granted = 0;
        await requirePremium(ctx, f, () => granted++);
        expect(granted, 0, reason: '$f must not open for a free user');
      }
      expect(paywall.shown, hasLength(5));
    });
  });

  group('PremiumLockedCard', () {
    testWidgets('says what the feature is and that it is Pro', (t) async {
      await pump(t, const PremiumLockedCard(feature: PremiumFeature.exerciseVideos));
      expect(find.text('Film your sets'), findsOneWidget);
      expect(find.textContaining('slow motion'), findsOneWidget);
      expect(find.text('UNLOCK'), findsOneWidget);
    });

    testWidgets('tapping it opens the paywall for that feature', (t) async {
      await pump(t, const PremiumLockedCard(feature: PremiumFeature.exerciseHistory));
      await t.tap(find.text('Beat your last session'));
      await t.pump();
      expect(paywall.shown, ['exerciseHistory']);
    });

    testWidgets('onUnlocked runs after a real purchase, and not after a dismissal', (t) async {
      var unlocked = 0;
      await pump(t, PremiumLockedCard(
          feature: PremiumFeature.videoTutorial, onUnlocked: () => unlocked++));
      await t.tap(find.byType(PremiumLockedCard));
      await t.pump();
      expect(unlocked, 0);

      paywall
        ..reportsPurchased = true
        ..grantsPro = true;
      await t.tap(find.byType(PremiumLockedCard));
      await t.pump();
      expect(unlocked, 1);
    });
  });

  group('the history section', () {
    testWidgets('locked: shows the card, a PRO badge, and none of the user\'s numbers', (t) async {
      // A history that never arrives proves nothing is waited on or shown.
      final never = Completer<ExerciseHistory?>().future;
      await pump(t, ExerciseHistorySection(
        exerciseName: 'Bench Press',
        history: never,
        onRetry: () {},
        locked: true,
      ));
      expect(find.text('History'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('Beat your last session'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Last time'), findsNothing);
    });

    testWidgets('unlocked: no card and no badge', (t) async {
      await pump(t, ExerciseHistorySection(
        exerciseName: 'Bench Press',
        history: Future.value(const ExerciseHistory([])),
        onRetry: () {},
      ));
      await t.pump();
      expect(find.text('PRO'), findsNothing);
      expect(find.text('Beat your last session'), findsNothing);
    });
  });
}
