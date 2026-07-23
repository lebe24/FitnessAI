import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Which backend the app talks to.
enum ServerEnvironment { local, production }

/// Dev/prod server switch.
///
/// - `production` → the live Cloud Run service (default)
/// - `local`      → the devtunnel in front of the local Docker server,
///                  used while fixing bugs before pushing to the cloud
///
/// The selection is persisted in the `app_settings` Hive box and loaded in
/// initDI() before any Dio service is constructed. Because every service
/// captures its baseUrl at construction time, switching requires an app
/// restart to take effect — the picker UI says so.
///
/// The switch UI (profile page) is only shown in debug builds; release
/// builds always run against production.
class ServerConfig {
  static const String _boxName = 'app_settings';
  static const String _envKey = 'server_environment';

  /// Local Docker server, exposed via VS Code devtunnel.
  static const String localUrl = 'https://2bq79ddl-8080.uks1.devtunnels.ms/';

  /// Live Cloud Run service (.env BACKEND_BASE_URL can override).
  static final String productionUrl = dotenv.env['BACKEND_BASE_URL'] ??
      'https://fitness-agent-vjpfphelaa-uc.a.run.app/';

  static ServerEnvironment _current = ServerEnvironment.production;
  static ServerEnvironment get current => _current;

  static bool get isLocal => _current == ServerEnvironment.local;

  /// REST base URL for the selected environment.
  static String get backendUrl =>
      isLocal ? localUrl : productionUrl;

  /// WebSocket base (wss://host, no trailing slash) for the selected env.
  static String get _wsBase => backendUrl
      .replaceFirst('https://', 'wss://')
      .replaceFirst(RegExp(r'/$'), '');

  static String get chatWsUrl => '$_wsBase/ws/chat';
  static String get agentWsUrl => '$_wsBase/ws/agent';

  /// Load the persisted selection. Called from initDI() before services are
  /// registered. Release builds ignore the stored value and force production.
  static Future<void> load() async {
    if (!kDebugMode) {
      _current = ServerEnvironment.production;
      return;
    }
    final box = await Hive.openBox(_boxName);
    final stored = box.get(_envKey) as String?;
    _current = stored == 'local'
        ? ServerEnvironment.local
        : ServerEnvironment.production;
  }

  /// Persist a new selection. Takes effect for new service instances only —
  /// restart the app to apply everywhere.
  static Future<void> setEnvironment(ServerEnvironment env) async {
    _current = env;
    final box = await Hive.openBox(_boxName);
    await box.put(_envKey, env == ServerEnvironment.local ? 'local' : 'production');
  }
}
