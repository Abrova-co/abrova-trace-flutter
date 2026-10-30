/// AbrovaTrace SDK constants
class AbrovaTraceConstants {
  /// Official AbrovaTrace API URL
  static const String apiUrl = 'https://trace.abrova.ir';

  /// SDK version. Must equal `version:` in pubspec.yaml (a test checks it);
  /// sent as `_sdk.sdk_version` and in the `User-Agent` header.
  static const String sdkVersion = '0.2.8';

  AbrovaTraceConstants._(); // Private constructor to prevent instantiation
}
