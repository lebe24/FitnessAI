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
  String? _error;

  UserEntity? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
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
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGmail(String email) async {
    _setLoading(true);
    try {
      _user = await _signInWithGmail(email);
      _error = null;
    } catch (e) {
      _error = e.toString();
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
    } catch (e) {
      _error = e.toString();
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
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
