import 'package:fitness/ui/core/constants/constant.dart';
import 'package:fitness/ui/features/profile/views/legal_document_page.dart';
import 'package:flutter_test/flutter_test.dart';

/// App Store guideline 3.1.2(c) rejected submission 7e82bfa5 for missing
/// subscription disclosure. These assertions pin the sentences that answer it.
///
/// A legal document is prose, so the usual review reflex is to tighten it. That
/// is how a required clause disappears — no test fails, nothing looks broken,
/// and the next rejection arrives three weeks later. Each expectation below is
/// something Apple checks for by name.
String _joined(List<LegalSection> sections) =>
    sections.map((s) => '${s.heading}\n${s.body}').join('\n\n').toLowerCase();

void main() {
  final terms = _joined(TermsAndConditionsPage.sections);
  final privacy = _joined(PrivacyPolicyPage.sections);

  group('Terms of Use — what 3.1.2(c) requires', () {
    test('names what is sold and how long each subscription runs', () {
      expect(terms, contains('monthly'));
      expect(terms, contains('yearly'));
      expect(terms, contains('1 month'));
      expect(terms, contains('1 year'));
    });

    test('says the price is shown before purchase', () {
      expect(terms, contains('price'));
      expect(terms, contains('before you confirm'));
    });

    test('states that the subscription renews by itself', () {
      expect(terms, contains('renews automatically'));
    });

    test('gives the 24-hour rule in both directions', () {
      // Turning auto-renew off, and when the renewal is charged.
      expect(terms, contains('24 hours before the end of the current period'));
      expect(terms, contains('within the 24 hours before the period ends'));
    });

    test('explains how to cancel, and what cancelling does not do', () {
      expect(terms, contains('apple account settings'));
      expect(terms, contains('deleting the app does not'));
    });

    test('discloses the trial converts, and that buying forfeits the rest', () {
      expect(terms, contains('free trial'));
      expect(terms, contains('converts into a paid subscription automatically'));
      expect(terms, contains('forfeited'));
    });

    test('points refunds at Apple rather than at us', () {
      expect(terms, contains('reportaproblem.apple.com'));
    });

    test('says the AI guidance is not medical advice', () {
      expect(terms, contains('not medical advice'));
    });
  });

  group('Privacy Policy — what the App Privacy questionnaire declares', () {
    test('names every category the app actually collects', () {
      for (final category in [
        'email',
        'height',
        'weight',
        'date of birth',
        'workouts',
        'photos',
        'error reports',
      ]) {
        expect(privacy, contains(category), reason: 'missing: $category');
      }
    });

    test('covers Sign in with Apple private relay', () {
      expect(privacy, contains('relay address'));
    });

    test('says data is neither sold nor used for advertising', () {
      expect(privacy, contains('do not sell your personal data'));
      expect(privacy, contains('advertis'));
    });

    test('tells the user how to delete everything', () {
      expect(privacy, contains('delete account'));
    });
  });

  group('the app and the website must not disagree', () {
    test('one support address, used everywhere', () {
      expect(Constant.supportEmail, 'support@befit.ai');
      expect(terms, contains(Constant.supportEmail));
      expect(privacy, contains(Constant.supportEmail));

      // The address the app used to carry in three places, two of which
      // disagreed with each other and with the website.
      expect(terms, isNot(contains('support@befitai.app')));
      expect(privacy, isNot(contains('support@befitai.app')));
    });

    test('both documents carry the same section count as the website', () {
      expect(TermsAndConditionsPage.sections, hasLength(15));
      expect(PrivacyPolicyPage.sections, hasLength(14));
    });

    test('the contracting entity is stated in both', () {
      expect(terms, contains(Constant.legalEntity.toLowerCase()));
      expect(privacy, contains(Constant.legalEntity.toLowerCase()));
      expect(terms, contains(Constant.legalJurisdiction.toLowerCase()));
    });
  });
}
