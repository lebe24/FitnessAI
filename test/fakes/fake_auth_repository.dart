import 'package:fitness/domain/models/user.dart';
import 'package:fitness/domain/repositories/auth_repository.dart';
import '../fixtures/fixtures.dart';

class FakeAuthRepository implements AuthRepository {
  UserEntity? _currentUser = Fixtures.user();
  Exception? signInWithGoogleError;
  Exception? signInWithGmailError;
  Exception? signOutError;
  Exception? deleteAccountError;

  bool signOutCalled = false;
  bool deleteAccountCalled = false;
  String? lastGmailEmail;

  void setCurrentUser(UserEntity? user) => _currentUser = user;

  @override
  UserEntity? getCurrentUser() => _currentUser;

  @override
  Future<UserEntity?> signInWithGoogle() async {
    if (signInWithGoogleError != null) throw signInWithGoogleError!;
    return _currentUser;
  }

  @override
  Future<UserEntity?> signInWithGmail(String email) async {
    if (signInWithGmailError != null) throw signInWithGmailError!;
    lastGmailEmail = email;
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    if (signOutError != null) throw signOutError!;
    signOutCalled = true;
    _currentUser = null;
  }

  @override
  Future<void> deleteAccount() async {
    if (deleteAccountError != null) throw deleteAccountError!;
    deleteAccountCalled = true;
    _currentUser = null;
  }
}
