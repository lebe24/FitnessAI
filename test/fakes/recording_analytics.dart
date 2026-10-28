import 'package:fitness/data/services/analytics/analytics_service.dart';

/// Records what would have been sent, so the tests can check the privacy rules
/// on the real payload rather than on the helper in isolation.
class RecordingAnalytics implements AnalyticsService {
  final events = <(String, Map<String, Object?>?)>[];
  final screens = <String>[];
  final superProps = <String, Object>{};
  String? identified;
  bool wasReset = false;
  bool _on = true;
  Object? throwOnTrack;

  @override
  bool get enabled => _on;
  @override
  Future<void> init() async {}
  @override
  Future<void> identify(String userId) async => identified = userId;
  @override
  Future<void> reset() async => wasReset = true;
  @override
  Future<void> track(String event, [Map<String, Object?>? properties]) async {
    if (throwOnTrack != null) throw throwOnTrack!;
    events.add((event, properties));
  }

  @override
  Future<void> screen(String name) async => screens.add(name);
  @override
  Future<void> setSuperProperty(String key, Object value) async =>
      superProps[key] = value;
  @override
  Future<void> setEnabled(bool enabled) async => _on = enabled;
}
