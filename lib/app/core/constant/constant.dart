import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constant {
  static const String appName = "Fitness AI";
  static const String welcomeMessage = "Welcome to Fitness AI";
  static const String onboardingMessage = "Let's get started with your fitness journey!";

  // supabase client
  static final supabaseUrl = dotenv.env['SUPABASE_URL'];
  static final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  // Oauth
  static final oauthWebClient = dotenv.env['Oauth_webClientId'];
  static final iosClient = dotenv.env['OAUTH_IOS_CLIENT'];
  static final oauthAndroidClient = dotenv.env['OAUTH_ANDROID_CLIENT'];
}