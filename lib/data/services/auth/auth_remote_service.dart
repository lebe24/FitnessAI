import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/data/models/auth/user_model.dart';
import 'package:fitness/domain/models/sign_in_cancelled.dart';
import 'package:fitness/domain/models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  /// Native Google sign-in (mobile). Exchanges tokens with Supabase.
  /// Returns the authenticated user model after successful sign-in.
  Future<User> signInWithGoogle();

  /// Native Sign in with Apple. Exchanges Apple's identity token with Supabase.
  ///
  /// Required by App Store guideline 4.8: an app offering a third-party login
  /// has to offer one that limits collection to name and email and lets the
  /// user withhold their real address. Apple's private relay is what satisfies
  /// the second half, which email/password cannot.
  Future<User> signInWithApple();

  /// Verify and sign in user by Gmail address
  Future<User> signInWithGmail(String email);

  /// Email + password, for people without a Google account — and for App
  /// Review, who cannot complete an OAuth flow for credentials they do not
  /// have.
  Future<User> signUpWithEmail(String email, String password);
  Future<User> signInWithEmail(String email, String password);

  Future<void> signOut();
  UserEntity? getCurrentUser();
  Future<void> deleteAccount();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl();

  final client = sl<SupabaseClient>();
  
  @override
  Future<User> signInWithGoogle() async {
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google sign-in did not return an ID token. '
          'Ensure serverClientId is configured correctly.',
        );
      }
      final rawNonce = sl<String>(instanceName: 'googleNonce');
      final authorization = await account.authorizationClient.authorizationForScopes(
        ['email', 'profile'],
      );
      final AuthResponse response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization?.accessToken,
        nonce: rawNonce,
      );
      final user = response.user;
      if (user == null) {
        throw Exception('Sign in succeeded but no user was returned');
      }
      return user;
    } on AuthException catch (e) {
      debugPrint('Supabase AuthException → message: ${e.message}, code: ${e.code}, status: ${e.statusCode}');
      throw Exception(e.message);
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException → $e');
      throw Exception(e.toString());
    }
  }
  
  @override
  Future<User> signInWithApple() async {
    // Apple sees only the hash; Supabase needs the original to verify that the
    // token it is handed was minted for this request. Generated per call —
    // reusing one across sign-ins would defeat the replay protection.
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Apple sign-in did not return an identity token.');
      }

      final AuthResponse response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Sign in succeeded but no user was returned');
      }

      // Apple sends the name on the FIRST authorization only, and never again
      // — not on any later sign-in, and not in the identity token. If it is not
      // captured here the profile has no name for the life of the account.
      final name = _appleFullName(credential);
      if (name != null && (user.userMetadata?['full_name'] as String?) == null) {
        try {
          final updated = await client.auth.updateUser(
            UserAttributes(data: {'full_name': name}),
          );
          return updated.user ?? user;
        } catch (e) {
          // A missing display name is not worth failing a sign-in over.
          debugPrint('Could not store the Apple display name — $e');
        }
      }
      return user;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const SignInCancelled();
      }
      debugPrint('SignInWithAppleAuthorizationException → ${e.code}: ${e.message}');
      throw Exception(e.message);
    } on AuthException catch (e) {
      debugPrint('Supabase AuthException → message: ${e.message}, code: ${e.code}, status: ${e.statusCode}');
      throw Exception(e.message);
    }
  }

  /// Apple gives the name in parts, and either part can be absent.
  static String? _appleFullName(AuthorizationCredentialAppleID c) {
    final parts = [c.givenName, c.familyName]
        .whereType<String>()
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' ');
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  @override
  Future<User> signInWithGmail(String email) async {
    try {
      // Check if email is a Gmail address
      final normalizedEmail = email.toLowerCase().trim();
      if (!normalizedEmail.endsWith('@gmail.com')) {
        throw Exception('Please enter a valid Gmail address');
      }

      final account = await GoogleSignIn.instance.authenticate();

      if (account.email.toLowerCase() != normalizedEmail) {
        await GoogleSignIn.instance.signOut();
        throw Exception('The Gmail address does not match. Please use ${account.email} or sign in with the correct account.');
      }

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google sign-in did not return an ID token.');
      }
      final rawNonce = sl<String>(instanceName: 'googleNonce');
      final authorization = await account.authorizationClient.authorizationForScopes(
        ['email', 'profile'],
      );
      final AuthResponse response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization?.accessToken,
        nonce: rawNonce,
      );
      final user = response.user;
      if (user == null) {
        throw Exception('Sign in succeeded but no user was returned');
      }
      if (user.email?.toLowerCase() != normalizedEmail) {
        throw Exception('Email verification failed. Please try again.');
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> signUpWithEmail(String email, String password) async {
    final AuthResponse response = await client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Sign up succeeded but no user was returned');
    }

    // Supabase returns a user with no session when email confirmation is
    // switched on for the project. The account exists but cannot be used yet,
    // and silently continuing would drop the user into a signed-out app.
    if (response.session == null) {
      throw const AuthException('Email not confirmed');
    }
    return user;
  }

  @override
  Future<User> signInWithEmail(String email, String password) async {
    final AuthResponse response = await client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw Exception('Sign in succeeded but no user was returned');
    }
    return user;
  }

  @override
  Future<void> signOut() async {
    try {
      // Sign out from Google Sign In
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.signOut();
      
      // Sign out from Supabase
      await client.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  @override
  UserEntity? getCurrentUser() {
    final user = client.auth.currentUser;
    if (user == null) return null;
    
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.userMetadata?['full_name'] as String? ?? 
            user.userMetadata?['name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String? ??
                 user.userMetadata?['picture'] as String?,
    );
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }
      
      // Delete the user account from Supabase Auth
      // Note: client.auth.deleteUser() doesn't exist in GoTrueClient
      // We need to use an Edge Function that handles the deletion server-side
      // The Edge Function should use the service role key for security
      
      // Call Edge Function to delete user
      final response = await client.functions.invoke(
        'delete-user',
        body: {'userId': user.id},
      );
      
      if (response.status != 200) {
        final errorData = response.data;
        final errorMessage = errorData != null && errorData is Map
            ? errorData['error']?.toString() ?? 
              errorData['message']?.toString() ?? 
              'Failed to delete user'
            : 'Failed to delete user: HTTP ${response.status}';
        throw Exception(errorMessage);
      }
      
      // Sign out from Google Sign In after successful deletion
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.signOut();
      
      // Sign out from Supabase to clear local session
      await client.auth.signOut();
    } catch (e) {
      // If Edge Function doesn't exist, provide helpful error message
      if (e.toString().contains('Function not found') || 
          e.toString().contains('404') ||
          e.toString().contains('not found')) {
        throw Exception(
          'Delete account feature requires a Supabase Edge Function named "delete-user". '
          'Please set up the Edge Function or contact support.',
        );
      }
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }
}