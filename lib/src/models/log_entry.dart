/// Log level for AbrovaTrace logging
enum LogLevel {
  trace('trace'),
  debug('debug'),
  info('info'),
  warn('warn'),
  error('error'),
  fatal('fatal');

  final String value;
  const LogLevel(this.value);
}

/// A single log entry to be sent to AbrovaTrace
class LogEntry {
  final String message;
  final LogLevel level;
  final DateTime? timestamp;
  final Map<String, dynamic>? metadata;
  final String? userId;

  LogEntry({
    required this.message,
    this.level = LogLevel.info,
    this.timestamp,
    this.metadata,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'level': level.value,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
      if (userId != null) 'userId': userId,
    };
  }
}
