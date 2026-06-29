import 'package:fitness/ui/core/di.dart';
import 'package:fitness/data/models/auth/user_model.dart';
import 'package:fitness/domain/models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  /// Native Google sign-in (mobile). Exchanges tokens with Supabase.
  /// Returns the authenticated user model after successful sign-in.
  Future<User> signInWithGoogle();

  /// Verify and sign in user by Gmail address
  Future<User> signInWithGmail(String email);

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