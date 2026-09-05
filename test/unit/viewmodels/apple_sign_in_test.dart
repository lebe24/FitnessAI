import 'package:fitness/domain/models/sign_in_cancelled.dart';
import 'package:fitness/domain/use_cases/auth/delete_account.dart';
import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/domain/use_cases/auth/sign_in_apple.dart';
import 'package:fitness/domain/use_cases/auth/sign_in_email.dart';
import 'package:fitness/domain/use_cases/auth/sign_in_gmail.dart';
import 'package:fitness/domain/use_cases/auth/sign_in_google.dart';
import 'package:fitness/domain/use_cases/auth/sign_out.dart';
import 'package:fitness/domain/use_cases/auth/sign_up_email.dart';
import 'package:fitness/ui/features/auth/view_models/auth_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fixtures/fixtures.dart';

/// Sign in with Apple exists to answer App Store guideline 4.8, so the paths
/// that matter are the ones a reviewer walks: it signs you in, and backing out
/// of Apple's sheet is not treated as a failure.
void main() {
  late FakeAuthRepository repo;

  AuthViewModel viewModel() => AuthViewModel(
        signInWithGoogle: SignInWithGoogle(repo),
        signInWithApple: SignInWithApple(repo),
        signInWithGmail: SignInWithGmail(repo),
        signUpWithEmail: SignUpWithEmail(repo),
        signInWithEmail: SignInWithEmail(repo),
        signOut: SignOut(repo),
        getCurrentUser: GetCurrentUser(repo),
        deleteAccount: DeleteAccount(repo),
      );

  setUp(() {
    repo = FakeAuthRepository();
  });

  test('a completed authorization signs the user in', () async {
    final vm = viewModel();

    await vm.signInWithApple();

    expect(vm.isAuthenticated, isTrue);
    expect(vm.user?.id, Fixtures.user().id);
    expect(vm.error, isNull);
    expect(vm.isLoading, isFalse);
  });

  test('backing out of the sheet is silent, not an error banner', () async {
    repo.signInWithAppleError = _cancelled();
    final vm = viewModel();

    await vm.signInWithApple();

    // The error object still exists — the view model records what happened —
    // but it is marked silent so nothing is put on screen, and it offers no
    // retry, because there is nothing to retry.
    expect(vm.error, isNotNull);
    expect(vm.error!.silent, isTrue,
        reason: 'changing your mind must not be reported as a failure');
    expect(vm.error!.canRetry, isFalse);
    expect(vm.isAuthenticated, isFalse);
    expect(vm.isLoading, isFalse);
  });

  test('a real failure is surfaced to the user', () async {
    repo.signInWithAppleError = Exception('token exchange rejected');
    final vm = viewModel();

    await vm.signInWithApple();

    expect(vm.error, isNotNull);
    expect(vm.error!.silent, isFalse);
    expect(vm.isAuthenticated, isFalse);
  });

  test('loading is cleared whichever way it ends', () async {
    repo.signInWithAppleError = _cancelled();
    final vm = viewModel();
    await vm.signInWithApple();
    expect(vm.isLoading, isFalse);

    repo.signInWithAppleError = null;
    await vm.signInWithApple();
    expect(vm.isLoading, isFalse);
  });
}

/// What the data layer raises when Apple reports `AuthorizationErrorCode.canceled`.
Exception _cancelled() => const SignInCancelled();
