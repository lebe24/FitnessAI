import 'dart:io';

import 'package:fitness/data/services/analytics/analytics.dart';
import 'package:fitness/data/services/analytics/analytics_service.dart';
import 'package:fitness/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../fakes/recording_analytics.dart';

/// The onboarding funnel is only as good as its events, so these pin down what
/// the view model reports as someone moves through the steps.
void main() {
  late RecordingAnalytics rec;

  // The view model autosaves each answer to Hive, so tests that pick answers
  // need a real (temporary) box to write to.
  setUpAll(() => Hive.init(Directory.systemTemp.createTempSync('onb').path));
  tearDownAll(() => Hive.close());

  setUp(() {
    rec = RecordingAnalytics();
    Analytics.use(rec);
  });
  tearDown(() => Analytics.use(NoopAnalyticsService()));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('the first step is recorded as a view when the screen opens', () async {
    OnboardingViewModel().trackInitialStep();
    await settle();

    expect(rec.events.map((e) => e.$1), ['onboarding_step_viewed']);
    expect(rec.events.single.$2,
        {'step': 'gender', 'index': 0, 'direction': 'start'});
  });

  test('moving forward completes one step and views the next', () async {
    final vm = OnboardingViewModel();
    vm.nextStep();
    await settle();

    expect(rec.events.map((e) => e.$1),
        ['onboarding_step_completed', 'onboarding_step_viewed']);
    expect(rec.events[0].$2, {'step': 'gender', 'index': 0});
    expect(rec.events[1].$2,
        {'step': 'workoutDays', 'index': 1, 'direction': 'forward'});
  });

  test('going back is a view, not a completion', () async {
    final vm = OnboardingViewModel()..nextStep();
    rec.events.clear();
    vm.previousStep();
    await settle();

    expect(rec.events.map((e) => e.$1), ['onboarding_step_viewed']);
    expect(rec.events.single.$2!['direction'], 'back');
    expect(rec.events.single.$2!['step'], 'gender');
  });

  test('walking the whole flow reports every step in order', () async {
    final vm = OnboardingViewModel();
    for (var i = 0; i < OnboardingStep.values.length - 1; i++) {
      vm.nextStep();
    }
    await settle();

    final viewed = rec.events
        .where((e) => e.$1 == 'onboarding_step_viewed')
        .map((e) => e.$2!['step'])
        .toList();
    expect(viewed, [
      'workoutDays',
      'goal',
      'experience',
      'heightAndWeight',
      'dob',
      'signup',
      'summary',
      'decide',
      'motivationQuote',
    ]);
  });

  test('no step event carries personal answers', () async {
    final vm = OnboardingViewModel();
    vm.selectGender('female');
    vm.selectHeight('172');
    vm.selectWeight('64');
    vm.selectDob('1998-04-02');
    for (var i = 0; i < 5; i++) {
      vm.nextStep();
    }
    await settle();

    final everything = rec.events.map((e) => '${e.$1} ${e.$2}').join(' ');
    for (final secret in ['female', '172', '64', '1998']) {
      expect(everything.contains(secret), isFalse, reason: secret);
    }
  });
}
