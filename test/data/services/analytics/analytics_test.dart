import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_bootstrap.dart';
import 'package:fitness/data/services/analytics/analytics_events.dart';
import 'package:fitness/data/services/analytics/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/recording_analytics.dart';

void main() {
  group('AnalyticsSanitizer', () {
    test('keeps plain scalars', () {
      final out = AnalyticsSanitizer.clean(
          {'count': 5, 'ratio': 0.5, 'ok': true, 'goal': 'Build Muscle'});
      expect(out, {'count': 5, 'ratio': 0.5, 'ok': true, 'goal': 'Build Muscle'});
    });

    test('drops personal-data keys whatever the value', () {
      final out = AnalyticsSanitizer.clean({
        'email': 'a',
        'Name': 'b',
        'message': 'my knee hurts',
        'notes': 'x',
        'image_path': '/tmp/me.jpg',
        'token': 't',
        'goal': 'ok',
      });
      expect(out.keys, ['goal']);
    });

    test('drops strings that look like email addresses', () {
      expect(AnalyticsSanitizer.clean({'who': 'me@example.com'}), isEmpty);
    });

    test('drops long strings, which are free text rather than labels', () {
      expect(AnalyticsSanitizer.clean({'detail': 'x' * 101}), isEmpty);
      expect(AnalyticsSanitizer.clean({'detail': 'x' * 100}), isNotEmpty);
    });

    test('drops nulls, lists, maps and objects so records never leak', () {
      final out = AnalyticsSanitizer.clean({
        'a': null,
        'list': [1, 2],
        'map': {'k': 'v'},
        'obj': Object(),
        'n': 1,
      });
      expect(out, {'n': 1});
    });

    test('turns enums into their names', () {
      expect(AnalyticsSanitizer.clean({'tier': _Tier.trial}), {'tier': 'trial'});
    });

    test('handles null and empty input', () {
      expect(AnalyticsSanitizer.clean(null), isEmpty);
      expect(AnalyticsSanitizer.clean({}), isEmpty);
    });
  });

  group('Analytics facade', () {
    late RecordingAnalytics rec;
    setUp(() {
      rec = RecordingAnalytics();
      Analytics.use(rec);
    });
    tearDown(() => Analytics.use(NoopAnalyticsService()));

    test('forwards events to the active service', () async {
      Analytics.track(AnalyticsEvents.workoutSaved, {'exercise_count': 5});
      await Future<void>.delayed(Duration.zero);
      expect(rec.events.single.$1, 'workout_saved');
      expect(rec.events.single.$2, {'exercise_count': 5});
    });

    test('is safe by default: with no service set it does nothing and never throws', () {
      Analytics.use(NoopAnalyticsService());
      expect(() => Analytics.track('anything'), returnsNormally);
      expect(() => Analytics.screen('home'), returnsNormally);
    });

    test('a failing service cannot break the caller', () async {
      rec.throwOnTrack = StateError('network down');
      expect(() => Analytics.track('x'), returnsNormally);
      await Future<void>.delayed(Duration.zero); // error is swallowed, not rethrown
    });

    test('identify, reset and super properties reach the service', () async {
      Analytics.identify('user-1');
      Analytics.reset();
      Analytics.setSuperProperty('access_tier', 'trial');
      await Future<void>.delayed(Duration.zero);
      expect(rec.identified, 'user-1');
      expect(rec.wasReset, isTrue);
      expect(rec.superProps['access_tier'], 'trial');
    });
  });

  group('event names', () {
    test('are unique, snake_case and past tense or noun-like', () {
      final names = [
        AnalyticsEvents.signedIn,
        AnalyticsEvents.signedUp,
        AnalyticsEvents.signedOut,
        AnalyticsEvents.accountDeleted,
        AnalyticsEvents.planGenerationStarted,
        AnalyticsEvents.planGenerated,
        AnalyticsEvents.planGenerationFailed,
        AnalyticsEvents.workoutSaved,
        AnalyticsEvents.workoutCompleted,
        AnalyticsEvents.mealScanned,
        AnalyticsEvents.bodyScanned,
        AnalyticsEvents.chatMessageSent,
        AnalyticsEvents.muscleMapOpened,
        AnalyticsEvents.muscleDetailOpened,
        AnalyticsEvents.muscleAdvisorAsked,
        AnalyticsEvents.paywallShown,
        AnalyticsEvents.paywallClosed,
        AnalyticsEvents.purchaseResult,
        AnalyticsEvents.restoreResult,
        AnalyticsEvents.trialOfferShown,
        AnalyticsEvents.trialEndingShown,
        AnalyticsEvents.analyticsOptedOut,
        AnalyticsEvents.welcomeCtaTapped,
        AnalyticsEvents.onboardingStepViewed,
        AnalyticsEvents.onboardingStepCompleted,
        AnalyticsEvents.onboardingAnswered,
        AnalyticsEvents.onboardingPathChosen,
        AnalyticsEvents.planGenerateTapped,
        AnalyticsEvents.trialOfferClosed,
        AnalyticsEvents.tabViewed,
        AnalyticsEvents.homeCardTapped,
        AnalyticsEvents.scanPhotoSelected,
        AnalyticsEvents.motivationGenerated,
      ];
      expect(names.toSet().length, names.length, reason: 'duplicate event name');
      for (final n in names) {
        expect(RegExp(r'^[a-z]+(_[a-z]+)*$').hasMatch(n), isTrue, reason: n);
      }
    });
  });

  group('screen names', () {
    test('use only the path', () {
      expect(AnalyticsBootstrap.screenNameFor('/'), 'splash');
      expect(AnalyticsBootstrap.screenNameFor('/home'), 'home');
      expect(AnalyticsBootstrap.screenNameFor('/workout-plan-detail'),
          'workout-plan-detail');
    });
  });
}

enum _Tier { trial }
