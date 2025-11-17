import 'dart:io';

import 'package:fitness/app/core/constant/constant.dart';
import 'package:fitness/app/core/di.dart';
import 'package:fitness/app/ui/auth/data/model/user_model.dart';
import 'package:fitness/app/ui/auth/domain/entities/user_entity.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  /// Native Google sign-in (mobile). Exchanges tokens with Supabase.
  /// Returns the authenticated user model after successful sign-in.
  Future<User> signInWithGoogle();

  Future<void> signOut();
  UserEntity? getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl();

  final client = sl<SupabaseClient>();
  
  @override
  Future<User> signInWithGoogle() async{
    try{
      GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: Platform.isAndroid ? Constant.oauthAndroidClient : Constant.iosClient,
        serverClientId: Constant.oauthWebClient,
      );
      GoogleSignInAccount account = await googleSignIn.authenticate();
      String idToken = account.authentication.idToken ?? "";
      final authorization = await account.authorizationClient.authorizationForScopes(
        [
          'email',
          'profile',
        ],
      ) ?? await account.authorizationClient.authorizationForScopes([
          'email',
          'profile',
        ]);
        final AuthResponse response = await client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: authorization?.accessToken,
        );
        final user = response.user;
        if (user == null) {
          throw Exception('Sign in succeeded but no user was returned');
        }
        return user;
    } catch (e) {
      throw Exception(e);
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
}