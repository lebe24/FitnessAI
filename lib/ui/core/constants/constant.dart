import 'package:fitness/ui/core/constants/server_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constant {
  static const String appName = "BEFIT - AI";
  static const String welcomeMessage = "Welcome to BEFIT - AI";
  static const String onboardingMessage = "Let's get started with your fitness journey!";

  // Support / legal contact — update once a real support inbox exists.
  static const String supportEmail = "support@befitai.app";

  // Backend URLs — resolved through the dev/prod server switch
  // (ServerConfig; debug-only picker in Profile → Server).
  static String get backendUrl => ServerConfig.backendUrl;
  static String get chatWsUrl => ServerConfig.chatWsUrl;
  static String get agentWsUrl => ServerConfig.agentWsUrl;

  // supabase client
  static final supabaseUrl = dotenv.env['SUPABASE_URL'] ;
  static final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];


  // Oauth
  // Web OAuth client ID (used as serverClientId for Google Sign-In)
  static final oauthWebClient = dotenv.env['Oauth_webClientId'];
  
  // iOS OAuth client ID
  // Format: {CLIENT_ID_PART}.apps.googleusercontent.com
  // Example: 846651404738-ap673f3cgaog3nh8n4a6vfa66oq1km44.apps.googleusercontent.com
  // The reverse client ID (com.googleusercontent.apps.{CLIENT_ID_PART}) is configured in ios/Runner/Info.plist as CFBundleURLSchemes
  static final iosClient = dotenv.env['OAUTH_IOS_CLIENT'];
  
  // Android OAuth client ID
  static final oauthAndroidClient = dotenv.env['OAUTH_ANDROID_CLIENT'];

  // API Keys
  static final youtubeApiKey = dotenv.env['YOUTUBE_API_KEY'];
  
  // API Base URLs
  static const String exerciseDbBaseUrl = 'https://api.exercisedb.io';
  
  // Add RapidAPI YouTube constants
  static const youtubeRapidApiBaseUrl = "https://youtube138.p.rapidapi.com";
  static const youtubeRapidApiHost = "youtube138.p.rapidapi.com";
  static final youtubeRapidApiKey = dotenv.env['YOUTUBE_RAPID_KEY'];

  static final toneOptions = [
    {
      "male":[
        "Alpha & Dominant",
        "Calm & Disciplined",
        "Warrior Mentality",
        "Coach Tone",
        "Hype"
      ],
      "female" :[
        "Confident & Empowering",
        "Soft but Encouraging",
        "High-Energy Badass",
        "Self-Care Focused",
        "Goal-Oriented"
      ]
    }
  ];
}