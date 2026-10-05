import 'dart:developer' as developer;

/// Log level for AbrovaTrace SDK
enum AbrovaTraceLogLevel {
  debug,
  info,
  warning,
  error,
}

/// Callback type for custom log handlers
typedef AbrovaTraceLogCallback = void Function(
  AbrovaTraceLogLevel level,
  String message,
  Object? error,
  StackTrace? stackTrace,
);

/// Internal logger for AbrovaTrace SDK
///
/// This logger:
/// - Uses dart:developer log() which works in both debug and release
/// - Respects the SDK's debug flag
/// - Allows developers to add custom log handlers
/// - Doesn't cause Flutter analyzer warnings like print()
class AbrovaTraceLogger {
  AbrovaTraceLogger._();

  static bool _isEnabled = false;
  static AbrovaTraceLogCallback? _customLogHandler;

  /// Enable or disable logging
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Set a custom log handler to receive all SDK logs
  ///
  /// This allows developers to:
  /// - Forward logs to their own logging system
  /// - Display logs in a debug console
  /// - Store logs for debugging
  ///
  /// Example:
  /// ```dart
  /// AbrovaTraceLogger.setLogHandler((level, message, error, stackTrace) {
  ///   // Forward to your logging system
  ///   myLogger.log(level.name, message);
  /// });
  /// ```
  static void setLogHandler(AbrovaTraceLogCallback? handler) {
    _customLogHandler = handler;
  }

  /// Log a debug message
  static void debug(String message) {
    _log(AbrovaTraceLogLevel.debug, message);
  }

  /// Log an info message
  static void info(String message) {
    _log(AbrovaTraceLogLevel.info, message);
  }

  /// Log a warning message
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(AbrovaTraceLogLevel.warning, message, error, stackTrace);
  }

  /// Log an error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(AbrovaTraceLogLevel.error, message, error, stackTrace);
  }

  static void _log(
    AbrovaTraceLogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // Only log when debug is enabled
    if (!_isEnabled) {
      return;
    }

    final formattedMessage = 'AbrovaTrace: $message';

    // Call custom handler if set
    _customLogHandler?.call(level, message, error, stackTrace);

    // Use dart:developer log which works in both debug and release
    // and can be viewed in DevTools
    developer.log(
      formattedMessage,
      name: 'AbrovaTrace',
      level: _levelToInt(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static int _levelToInt(AbrovaTraceLogLevel level) {
    switch (level) {
      case AbrovaTraceLogLevel.debug:
        return 500; // FINE
      case AbrovaTraceLogLevel.info:
        return 800; // INFO
      case AbrovaTraceLogLevel.warning:
        return 900; // WARNING
      case AbrovaTraceLogLevel.error:
        return 1000; // SEVERE
    }
  }
}
