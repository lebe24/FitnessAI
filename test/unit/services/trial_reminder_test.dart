import 'dart:io';

import 'package:fitness/data/services/billing/trial_reminder_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// The renewal notice has two ways to be wrong, and both damage trust more
/// than showing nothing: nagging on every launch, and telling someone who has
/// already cancelled that they are about to be charged.
void main() {
  final endsAt = DateTime(2026, 10, 2, 9, 30);

  group('when to remind', () {
    test('a trial ending soon, never reminded, gets the notice', () {
      expect(
        TrialReminderStorage.shouldRemind(
          trialEndingSoon: true,
          willRenew: true,
          endsAt: endsAt,
          lastRemindedFor: null,
        ),
        isTrue,
      );
    });

    test('the same trial is never shown twice', () {
      expect(
        TrialReminderStorage.shouldRemind(
          trialEndingSoon: true,
          willRenew: true,
          endsAt: endsAt,
          lastRemindedFor: endsAt,
        ),
        isFalse,
      );
    });

    test('a few seconds of drift between refreshes is the same trial', () {
      // Entitlement refreshes can report an end time that moves slightly.
      expect(
        TrialReminderStorage.shouldRemind(
          trialEndingSoon: true,
          willRenew: true,
          endsAt: endsAt.add(const Duration(seconds: 40)),
          lastRemindedFor: endsAt,
        ),
        isFalse,
      );
    });

    test('a later trial reminds again', () {
      // Trialled, lapsed, trialled again months on.
      expect(
        TrialReminderStorage.shouldRemind(
          trialEndingSoon: true,
          willRenew: true,
          endsAt: endsAt.add(const Duration(days: 90)),
          lastRemindedFor: endsAt,
        ),
        isTrue,
      );
    });

    test('someone who already cancelled is not told they will be charged', () {
      expect(
        TrialReminderStorage.shouldRemind(
          trialEndingSoon: true,
          willRenew: false,
          endsAt: endsAt,
          lastRemindedFor: null,
        ),
        isFalse,
        reason: 'their trial ends, but no payment is coming',
      );
    });

    test('a trial with time left is left alone', () {
      expect(
        TrialReminderStorage.shouldRemind(
          trialEndingSoon: false,
          willRenew: true,
          endsAt: endsAt,
          lastRemindedFor: null,
        ),
        isFalse,
      );
    });

    test('no end date means nothing to announce', () {
      expect(
        TrialReminderStorage.shouldRemind(
          trialEndingSoon: true,
          willRenew: true,
          endsAt: null,
          lastRemindedFor: null,
        ),
        isFalse,
      );
    });
  });

  group('remembering across launches', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('trial_reminder_test');
      Hive.init(dir.path);
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await Hive.close();
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('what was shown survives a restart', () async {
      expect(await TrialReminderStorage.lastRemindedFor(), isNull);

      await TrialReminderStorage.markShown(endsAt);
      // Closing and reopening is what a relaunch actually does.
      await Hive.close();
      Hive.init(dir.path);

      final stored = await TrialReminderStorage.lastRemindedFor();
      expect(stored, isNotNull);
      expect(stored!.difference(endsAt).abs(), lessThan(const Duration(seconds: 1)));
      expect(
        TrialReminderStorage.shouldRemind(
          trialEndingSoon: true,
          willRenew: true,
          endsAt: endsAt,
          lastRemindedFor: stored,
        ),
        isFalse,
      );
    });
  });
}
