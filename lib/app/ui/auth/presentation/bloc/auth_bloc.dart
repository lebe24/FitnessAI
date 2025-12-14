import 'package:fitness/app/ui/auth/domain/usecase/delete_account.dart';
import 'package:fitness/app/ui/auth/domain/usecase/get_current_user.dart';
import 'package:fitness/app/ui/auth/domain/usecase/sign_in_google.dart';
import 'package:fitness/app/ui/auth/domain/usecase/sign_in_gmail.dart';
import 'package:fitness/app/ui/auth/domain/usecase/sign_out.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithGoogle signInWithGoogle;
  final SignInWithGmail signInWithGmail;
  final SignOut signOut;
  final GetCurrentUser getCurrentUser;
  final DeleteAccount deleteAccount;

  AuthBloc({
    required this.signInWithGoogle,
    required this.signInWithGmail,
    required this.signOut,
    required this.getCurrentUser,
    required this.deleteAccount,
  }) : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      // Check if there's an existing user session
      final user = getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<SignInWithGoogleRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await signInWithGoogle();
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<SignInWithGmailRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await signInWithGmail(event.email);
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<SignOutRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await signOut();
        emit(AuthUnauthenticated());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<DeleteAccountRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await deleteAccount();
        emit(AuthUnauthenticated());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });
  }
}
