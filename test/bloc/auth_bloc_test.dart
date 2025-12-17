import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/ui/auth/presentation/bloc/auth_bloc.dart';
import 'package:fitness/app/ui/auth/presentation/bloc/auth_event.dart';
import 'package:fitness/app/ui/auth/presentation/bloc/auth_state.dart';
import 'package:fitness/app/ui/auth/domain/usecase/sign_in_google.dart';
import 'package:fitness/app/ui/auth/domain/usecase/sign_in_gmail.dart';
import 'package:fitness/app/ui/auth/domain/usecase/sign_out.dart';
import 'package:fitness/app/ui/auth/domain/usecase/get_current_user.dart';
import 'package:fitness/app/ui/auth/domain/usecase/delete_account.dart';
import 'package:fitness/app/ui/auth/domain/entities/user_entity.dart';
import '../helpers/test_helpers.dart';

class MockSignInWithGoogle extends Mock implements SignInWithGoogle {}
class MockSignInWithGmail extends Mock implements SignInWithGmail {}
class MockSignOut extends Mock implements SignOut {}
class MockGetCurrentUser extends Mock implements GetCurrentUser {}
class MockDeleteAccount extends Mock implements DeleteAccount {}

void main() {
  late AuthBloc authBloc;
  late MockSignInWithGoogle mockSignInWithGoogle;
  late MockSignInWithGmail mockSignInWithGmail;
  late MockSignOut mockSignOut;
  late MockGetCurrentUser mockGetCurrentUser;
  late MockDeleteAccount mockDeleteAccount;

  setUp(() {
    mockSignInWithGoogle = MockSignInWithGoogle();
    mockSignInWithGmail = MockSignInWithGmail();
    mockSignOut = MockSignOut();
    mockGetCurrentUser = MockGetCurrentUser();
    mockDeleteAccount = MockDeleteAccount();

    authBloc = AuthBloc(
      signInWithGoogle: mockSignInWithGoogle,
      signInWithGmail: mockSignInWithGmail,
      signOut: mockSignOut,
      getCurrentUser: mockGetCurrentUser,
      deleteAccount: mockDeleteAccount,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  test('initial state should be AuthInitial', () {
    expect(authBloc.state, equals(AuthInitial()));
  });

  blocTest<AuthBloc, AuthState>(
    'emits AuthAuthenticated when AppStarted and user exists',
    build: () {
      when(mockGetCurrentUser()).thenReturn(TestFixtures.getTestUser());
      return authBloc;
    },
    act: (bloc) => bloc.add(AppStarted()),
    expect: () => [
      AuthAuthenticated(TestFixtures.getTestUser()),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits AuthUnauthenticated when AppStarted and no user',
    build: () {
      when(mockGetCurrentUser()).thenReturn(null);
      return authBloc;
    },
    act: (bloc) => bloc.add(AppStarted()),
    expect: () => [
      AuthUnauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthAuthenticated] when SignInWithGoogleRequested succeeds',
    build: () {
      when(mockSignInWithGoogle())
          .thenAnswer((_) async => TestFixtures.getTestUser());
      return authBloc;
    },
    act: (bloc) => bloc.add(SignInWithGoogleRequested()),
    expect: () => [
      AuthLoading(),
      AuthAuthenticated(TestFixtures.getTestUser()),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthUnauthenticated] when SignInWithGoogleRequested returns null',
    build: () {
      when(mockSignInWithGoogle()).thenAnswer((_) async => null);
      return authBloc;
    },
    act: (bloc) => bloc.add(SignInWithGoogleRequested()),
    expect: () => [
      AuthLoading(),
      AuthUnauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthFailure] when SignInWithGoogleRequested throws',
    build: () {
      when(mockSignInWithGoogle())
          .thenThrow(Exception('Sign in failed'));
      return authBloc;
    },
    act: (bloc) => bloc.add(SignInWithGoogleRequested()),
    expect: () => [
      AuthLoading(),
      AuthFailure('Exception: Sign in failed'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthAuthenticated] when SignInWithGmailRequested succeeds',
    build: () {
      when(mockSignInWithGmail(any))
          .thenAnswer((_) async => TestFixtures.getTestUser());
      return authBloc;
    },
    act: (bloc) => bloc.add(SignInWithGmailRequested('test@example.com')),
    expect: () => [
      AuthLoading(),
      AuthAuthenticated(TestFixtures.getTestUser()),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthUnauthenticated] when SignOutRequested succeeds',
    build: () {
      when(mockSignOut()).thenAnswer((_) async => {});
      return authBloc;
    },
    act: (bloc) => bloc.add(SignOutRequested()),
    expect: () => [
      AuthLoading(),
      AuthUnauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthUnauthenticated] when DeleteAccountRequested succeeds',
    build: () {
      when(mockDeleteAccount()).thenAnswer((_) async => {});
      return authBloc;
    },
    act: (bloc) => bloc.add(DeleteAccountRequested()),
    expect: () => [
      AuthLoading(),
      AuthUnauthenticated(),
    ],
  );
}

