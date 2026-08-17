import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  group('TrialOffer labels', () {
    test('a one-week offer reads naturally in both forms', () {
      const t = TrialOffer(units: 1, unit: PeriodUnit.week);
      expect(t.label, '1-week');
      expect(t.phrase, '1 week');
    });

    test('seven days pluralises the sentence form only', () {
      const t = TrialOffer(units: 7, unit: PeriodUnit.day);
      expect(t.label, '7-day');
      expect(t.phrase, '7 days');
    });

    test('months and years are supported', () {
      expect(const TrialOffer(units: 3, unit: PeriodUnit.month).phrase,
          '3 months');
      expect(const TrialOffer(units: 1, unit: PeriodUnit.year).phrase, '1 year');
    });

    test('an unknown unit degrades to days rather than printing an enum', () {
      final t = const TrialOffer(units: 5, unit: PeriodUnit.unknown);
      expect(t.phrase, '5 days');
      expect(t.label, isNot(contains('unknown')));
    });
  });
}
