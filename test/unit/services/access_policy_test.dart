import 'package:fitness/data/services/billing/access_policy.dart';
import 'package:fitness/data/services/billing/complimentary_access.dart';
import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:fitness/domain/models/premium_feature.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the RevenueCat-backed service so the policy can be exercised
/// without the SDK. Only the three properties AccessPolicy reads are faked.
class _FakeSubs extends SubscriptionService {
  bool pro;
  bool trial;
  DateTime? expiry;
  bool renews;

  _FakeSubs({
    this.pro = false,
    this.trial = false,
    this.expiry,
    this.renews = true,
  });

  @override
  bool get isPro => pro;

  @override
  bool get isInTrial => trial;

  @override
  DateTime? get expirationDate => expiry;

  @override
  bool get willRenew => renews;
}

/// Complimentary access with a fixed answer, so the policy can be exercised
/// without a backend.
class _FakeComp extends ComplimentaryAccess {
  final bool granted;
  // No backend: the grant is supplied directly, and refresh() is a no-op.
  _FakeComp({this.granted = false});

  @override
  bool get isGranted => granted;
}

AccessPolicy _policy(_FakeSubs subs, {bool comp = false}) =>
    AccessPolicy(subs, _FakeComp(granted: comp));

void main() {
  group('tier', () {
    test('no entitlement is free', () {
      expect(_policy(_FakeSubs()).tier, AccessTier.free);
    });

    test('an active introductory offer is a trial', () {
      final p = _policy(_FakeSubs(pro: true, trial: true));
      expect(p.tier, AccessTier.trial);
      expect(p.isTrialling, isTrue);
    });

    test('an active non-trial entitlement is paid', () {
      expect(_policy(_FakeSubs(pro: true)).tier, AccessTier.paid);
    });
  });

  group('canUse', () {
    test('every premium feature is locked without an entitlement', () {
      final p = _policy(_FakeSubs());
      for (final f in PremiumFeature.values) {
        expect(p.canUse(f), isFalse, reason: f.name);
      }
    });

    test('a trial unlocks exactly what paying unlocks', () {
      // The whole point of using Apple's trial: there is no second code path
      // where a trialling user could be treated differently by mistake.
      final trialling = _policy(_FakeSubs(pro: true, trial: true));
      final paying = _policy(_FakeSubs(pro: true));
      for (final f in PremiumFeature.values) {
        expect(trialling.canUse(f), paying.canUse(f), reason: f.name);
        expect(trialling.canUse(f), isTrue, reason: f.name);
      }
    });

    test('access follows entitlement, not the clock', () {
      // An expiry in the past with the entitlement still active must not lock
      // the user out — Apple decides expiry, and a wrong device clock or a
      // grace period would otherwise strip access from a paying customer.
      final p = _policy(_FakeSubs(
        pro: true,
        expiry: DateTime.now().subtract(const Duration(days: 3)),
      ));
      expect(p.canUse(PremiumFeature.agentChat), isTrue);
      expect(p.daysRemaining, 0);
    });
  });

  group('messaging', () {
    test('days remaining floors and never goes negative', () {
      final p = _policy(_FakeSubs(
        pro: true,
        trial: true,
        expiry: DateTime.now().add(const Duration(days: 3, hours: 5)),
      ));
      expect(p.daysRemaining, 3);
    });

    test('a trial ending within two days is flagged', () {
      final soon = _policy(_FakeSubs(
        pro: true,
        trial: true,
        expiry: DateTime.now().add(const Duration(days: 1)),
      ));
      final later = _policy(_FakeSubs(
        pro: true,
        trial: true,
        expiry: DateTime.now().add(const Duration(days: 6)),
      ));
      expect(soon.trialEndingSoon, isTrue);
      expect(later.trialEndingSoon, isFalse);
    });

    test('a paying user is never flagged as a trial ending', () {
      final p = _policy(_FakeSubs(
        pro: true,
        expiry: DateTime.now().add(const Duration(hours: 6)),
      ));
      expect(p.trialEndingSoon, isFalse);
    });

    test('status reads correctly for each tier', () {
      expect(_policy(_FakeSubs()).statusLabel, isNull);

      expect(
        _policy(_FakeSubs(
          pro: true,
          trial: true,
          expiry: DateTime.now().add(const Duration(days: 4, hours: 2)),
        )).statusLabel,
        'Free trial · 4 days left',
      );

      expect(
        _policy(_FakeSubs(
          pro: true,
          trial: true,
          expiry: DateTime.now().add(const Duration(hours: 5)),
        )).statusLabel,
        'Trial ends today',
      );

      expect(_policy(_FakeSubs(pro: true)).statusLabel, 'Pro · active');

      // Cancelled but still inside the paid period — saying "active" would
      // imply it renews.
      expect(_policy(_FakeSubs(pro: true, renews: false)).statusLabel,
          'Pro · ends soon');
    });
  });

  group('complimentary access', () {
    test('a granted account unlocks everything without a subscription', () {
      final p = _policy(_FakeSubs(), comp: true);
      expect(p.tier, AccessTier.complimentary);
      for (final f in PremiumFeature.values) {
        expect(p.canUse(f), isTrue, reason: f.name);
      }
    });

    test('it reads as complimentary, not as a subscription', () {
      // The billing screen must not tell a reviewer their plan renews.
      expect(_policy(_FakeSubs(), comp: true).statusLabel,
          'Pro · complimentary');
    });

    test('a real subscription takes precedence over a grant', () {
      // Someone comped who later subscribes should see their actual plan.
      final p = _policy(_FakeSubs(pro: true), comp: true);
      expect(p.tier, AccessTier.paid);
      expect(p.statusLabel, 'Pro · active');
    });

    test('a trial takes precedence over a grant', () {
      final p = _policy(_FakeSubs(pro: true, trial: true), comp: true);
      expect(p.tier, AccessTier.trial);
    });

    test('no grant and no subscription is still free', () {
      final p = _policy(_FakeSubs());
      expect(p.tier, AccessTier.free);
      expect(p.canUse(PremiumFeature.agentChat), isFalse);
    });

    test('a paying user keeps access when no grant is present', () {
      // Guards the OR: access must never require the backend to answer.
      final p = _policy(_FakeSubs(pro: true));
      expect(p.canUse(PremiumFeature.nutritionScanner), isTrue);
    });
  });
}
