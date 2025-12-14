import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constant {
  static const String appName = "BEFIT - AI";
  static const String welcomeMessage = "Welcome to BEFIT - AI";
  static const String onboardingMessage = "Let's get started with your fitness journey!";

  // supabase client
  static final supabaseUrl = dotenv.env['SUPABASE_URL'];
  static final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  // Oauth
  static final oauthWebClient = dotenv.env['Oauth_webClientId'];
  static final iosClient = dotenv.env['OAUTH_IOS_CLIENT'];
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