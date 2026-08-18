import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('billing contract', () {
    test('entitlement id matches the RevenueCat dashboard identifier', () {
      // Changing this silently unlocks/locks Pro for everyone — it must stay
      // in sync with Project → Entitlements in RevenueCat.
      expect(kProEntitlement, 'Befit AI - fitness Pro');
    });
  });

  group('PurchaseResult', () {
    test('cancellation is not surfaced to the user', () {
      const r = PurchaseResult(PurchaseOutcome.cancelled);
      expect(r.isSuccess, isFalse);
      expect(r.shouldShowMessage, isFalse,
          reason: 'backing out of the sheet is a choice, not an error');
    });

    test('success shows nothing and reads as success', () {
      const r = PurchaseResult(PurchaseOutcome.success);
      expect(r.isSuccess, isTrue);
      expect(r.shouldShowMessage, isFalse);
    });

    test('real failures carry a message the UI can show', () {
      for (final o in [
        PurchaseOutcome.networkError,
        PurchaseOutcome.storeError,
        PurchaseOutcome.alreadyOwned,
        PurchaseOutcome.paymentDisabled,
        PurchaseOutcome.pending,
      ]) {
        expect(PurchaseResult(o, 'msg').shouldShowMessage, isTrue,
            reason: '$o should tell the user what happened');
      }
    });
  });

  test('service degrades safely when no API key is configured', () {
    final s = SubscriptionService();
    expect(s.isConfigured, isFalse);
    expect(s.isPro, isFalse, reason: 'never grant Pro without RevenueCat');
    expect(s.availablePackages, isEmpty);
    expect(s.monthly, isNull);
    expect(s.yearly, isNull);
  });
}
