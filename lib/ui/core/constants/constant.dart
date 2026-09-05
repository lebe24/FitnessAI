import 'package:fitness/ui/core/constants/server_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constant {
  static const String appName = "BEFIT - AI";
  static const String welcomeMessage = "Welcome to BEFIT - AI";
  static const String onboardingMessage = "Let's get started with your fitness journey!";

  // ── Legal / contact ───────────────────────────────────────────────────────
  // These mirror befit_web/lib/legal.ts. The two documents are compared by
  // reviewers, so a value that differs between the app and the website is a
  // finding waiting to happen — change them in both places or in neither.

  /// The support inbox. Matches CONTACT in befit_web/lib/legal.ts and the
  /// address given as the App Store support contact.
  ///
  /// TEMPORARY — a personal address standing in until support@befit.ai is
  /// live. It is published in the App Store listing and on both legal
  /// documents, so swap it the moment the real inbox receives mail. This
  /// constant and the website's CONTACT are the only two places to change.
  static const String supportEmail = "emmanuel.philipel@yahoo.com";

  /// The entity a user is contracting with.
  ///
  /// Must stay identical to the Copyright field in App Store Connect, which
  /// names the developer-account holder, and to ENTITY in
  /// befit_web/lib/legal.ts.
  static const String legalEntity = "BeFit AI";

  /// Whose law governs the terms.
  static const String legalJurisdiction = "England and Wales";

  /// Shown as "Last updated" on both documents. Bump when the wording changes.
  static const String legalLastUpdated = "5 September 2026";

  // Backend URLs — resolved through the dev/prod server switch
  // (ServerConfig; flip _kDevEnvironment in server_config.dart to develop
  // against the local Docker server).
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