import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Which backend the app talks to.
enum ServerEnvironment { local, production }

// ─────────────────────────────────────────────────────────────────────────────
//  DEV TOGGLE — flip this line while debugging, then flip it back.
//
//    ServerEnvironment.production  → live Cloud Run  (default, ships to users)
//    ServerEnvironment.local       → local Docker server via devtunnel
//
//  Release builds ignore this and always use production, so a stray `local`
//  can never ship. Restart the app after changing it — Dio services capture
//  their base URL when they are constructed.
// ─────────────────────────────────────────────────────────────────────────────
const ServerEnvironment _kDevEnvironment = ServerEnvironment.production;

/// Resolves the backend URLs for the selected environment.
///
/// The switch lives in code (`_kDevEnvironment` above) rather than in the app
/// UI — it is a development tool, not a user-facing feature.
class ServerConfig {
  /// Local Docker server, exposed via VS Code devtunnel.
  static final String productionUrl = dotenv.env['BACKEND_BASE_URL'] ??
      'https://fitness-agent-vjpfphelaa-uc.a.run.app/';

  /// Live Cloud Run service (.env BACKEND_BASE_URL can override).
  static const String localUrl =  'https://2bq79ddl-8080.uks1.devtunnels.ms/' ;

  /// Release builds are always pinned to production.
  static ServerEnvironment get current =>
      kReleaseMode ? ServerEnvironment.production : _kDevEnvironment;

  static bool get isLocal => current == ServerEnvironment.local;

  /// REST base URL for the selected environment.
  static String get backendUrl => isLocal ? localUrl : productionUrl;

  /// WebSocket base (wss://host, no trailing slash) for the selected env.
  static String get _wsBase => backendUrl
      .replaceFirst('https://', 'wss://')
      .replaceFirst(RegExp(r'/$'), '');

  static String get chatWsUrl => '$_wsBase/ws/chat';
  static String get agentWsUrl => '$_wsBase/ws/agent';
}
