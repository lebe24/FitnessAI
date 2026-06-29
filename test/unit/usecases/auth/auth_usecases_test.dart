import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/domain/use_cases/auth/sign_in_google.dart';
import 'package:fitness/domain/use_cases/auth/sign_in_gmail.dart';
import 'package:fitness/domain/use_cases/auth/sign_out.dart';
import 'package:fitness/domain/use_cases/auth/delete_account.dart';
import '../../../fakes/fake_auth_repository.dart';
import '../../../fixtures/fixtures.dart';

void main() {
  late FakeAuthRepository repo;

  setUp(() => repo = FakeAuthRepository());

  // ── GetCurrentUser ─────────────────────────────────────────────────────────

  group('GetCurrentUser', () {
    test('returns user when logged in', () {
      final result = GetCurrentUser(repo)();
      expect(result, isNotNull);
      expect(result!.id, 'user-001');
    });

    test('returns null when no user is logged in', () {
      repo.setCurrentUser(null);
      expect(GetCurrentUser(repo)(), isNull);
    });
  });

  // ── SignInWithGoogle ───────────────────────────────────────────────────────

  group('SignInWithGoogle', () {
    test('returns user on success', () async {
      final result = await SignInWithGoogle(repo)();
      expect(result?.id, 'user-001');
    });

    test('returns null when repository returns null', () async {
      repo.setCurrentUser(null);
      final result = await SignInWithGoogle(repo)();
      expect(result, isNull);
    });

    test('propagates exception from repository', () async {
      repo.signInWithGoogleError = Exception('Google sign-in failed');
      expect(() => SignInWithGoogle(repo)(), throwsException);
    });
  });

  // ── SignInWithGmail ────────────────────────────────────────────────────────

  group('SignInWithGmail', () {
    const email = 'test@example.com';

    test('returns user on success', () async {
      final result = await SignInWithGmail(repo)(email);
      expect(result, isNotNull);
      expect(repo.lastGmailEmail, email);
    });

    test('returns null when repository returns null', () async {
      repo.setCurrentUser(null);
      final result = await SignInWithGmail(repo)(email);
      expect(result, isNull);
    });

    test('propagates exception from repository', () async {
      repo.signInWithGmailError = Exception('Gmail sign-in failed');
      expect(() => SignInWithGmail(repo)(email), throwsException);
    });
  });

  // ── SignOut ────────────────────────────────────────────────────────────────

  group('SignOut', () {
    test('calls repository and completes', () async {
      await SignOut(repo)();
      expect(repo.signOutCalled, true);
      expect(repo.getCurrentUser(), isNull);
    });

    test('propagates exception from repository', () async {
      repo.signOutError = Exception('Sign out failed');
      expect(() => SignOut(repo)(), throwsException);
    });
  });

  // ── DeleteAccount ──────────────────────────────────────────────────────────

  group('DeleteAccount', () {
    test('calls repository and clears user', () async {
      await DeleteAccount(repo)();
      expect(repo.deleteAccountCalled, true);
      expect(repo.getCurrentUser(), isNull);
    });

    test('propagates exception from repository', () async {
      repo.deleteAccountError = Exception('Delete failed');
      expect(() => DeleteAccount(repo)(), throwsException);
    });
  });
}
