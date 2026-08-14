/// Build identity, without a plugin.
///
/// `package_info_plus` would read this from the platform bundle, but it is a
/// native plugin and not worth a channel round-trip for one string in an error
/// log. The value is compiled in instead.
///
/// CI passes the real value so release builds are always accurate:
///
/// ```bash
/// flutter build ipa --release --dart-define=APP_VERSION=1.0.0+4
/// ```
///
/// The default below is the fallback for local builds run without the flag.
/// It is only used to label diagnostics, so drifting by a build number is
/// harmless — but keep it roughly in step with `version:` in pubspec.yaml.
class AppInfo {
  static const String version =
      String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0+4');

  /// True when the version was injected at build time rather than defaulted,
  /// so a log reader can tell an exact version from an approximate one.
  static const bool versionIsExact =
      bool.hasEnvironment('APP_VERSION');
}
