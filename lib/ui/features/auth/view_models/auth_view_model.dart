import 'package:fitness/data/services/diagnostics/error_log_service.dart';
import 'package:fitness/domain/models/friendly_error.dart';
import 'package:fitness/domain/models/user.dart';
import 'package:fitness/domain/use_cases/auth/delete_account.dart';
import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/domain/use_cases/auth/sign_in_gmail.dart';
import 'package:fitness/domain/use_cases/auth/sign_in_google.dart';
import 'package:fitness/domain/use_cases/auth/sign_out.dart';
import 'package:flutter/foundation.dart';

class AuthViewModel extends ChangeNotifier {
  final SignInWithGoogle _signInWithGoogle;
  final SignInWithGmail _signInWithGmail;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;
  final DeleteAccount _deleteAccount;

  AuthViewModel({
    required SignInWithGoogle signInWithGoogle,
    required SignInWithGmail signInWithGmail,
    required SignOut signOut,
    required GetCurrentUser getCurrentUser,
    required DeleteAccount deleteAccount,
  })  : _signInWithGoogle = signInWithGoogle,
        _signInWithGmail = signInWithGmail,
        _signOut = signOut,
        _getCurrentUser = getCurrentUser,
        _deleteAccount = deleteAccount;

  UserEntity? _user;
  bool _isLoading = false;
  FriendlyError? _error;

  UserEntity? get user => _user;
  bool get isLoading => _isLoading;

  /// The failure to show the user, already phrased for them. The technical
  /// cause goes to `error_logs` instead of the screen.
  FriendlyError? get error => _error;

  bool get isAuthenticated => _user != null;

  void checkSession() {
    _user = _getCurrentUser();
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      _user = await _signInWithGoogle();
      _error = null;
    } catch (e, st) {
      _error = FriendlyError.from(e, fallback: FriendlyError.signInFailed);
      ErrorLogService.report(
          area: _area, action: 'sign_in_google', error: e, stackTrace: st);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGmail(String email) async {
    _setLoading(true);
    try {
      _user = await _signInWithGmail(email);
      _error = null;
    } catch (e, st) {
      _error = FriendlyError.from(e, fallback: FriendlyError.signInFailed);
      ErrorLogService.report(
          area: _area, action: 'sign_in_gmail', error: e, stackTrace: st);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _signOut();
      _user = null;
      _error = null;
    } catch (e, st) {
      _error = FriendlyError.from(e, fallback: _signOutFailed);
      ErrorLogService.report(
          area: _area, action: 'sign_out', error: e, stackTrace: st);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    _setLoading(true);
    try {
      await _deleteAccount();
      _user = null;
      _error = null;
    } catch (e, st) {
      _error = FriendlyError.from(e, fallback: _deleteFailed);
      ErrorLogService.report(
          area: _area, action: 'delete_account', error: e, stackTrace: st);
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  static const String _area = 'onboarding.auth';

  static const _signOutFailed = FriendlyError(
    title: "Couldn't sign you out",
    message: 'Check your connection and try again.',
  );

  static const _deleteFailed = FriendlyError(
    title: "Couldn't delete your account",
    message:
        'Nothing has been removed. Try again, or email support@befit.ai and we '
        'will do it for you.',
  );

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
