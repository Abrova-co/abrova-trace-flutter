import 'package:flutter_test/flutter_test.dart';
import 'package:abrova_trace_flutter_sdk/abrova_trace_flutter_sdk.dart';
import 'package:abrova_trace_flutter_sdk/src/services/abrova_trace_logger.dart';

void main() {
  group('AbrovaTraceLogger', () {
    setUp(() {
      AbrovaTraceLogger.setEnabled(false);
      AbrovaTraceLogger.setLogHandler(null);
    });

    test('does not call handler when disabled', () {
      var called = false;
      AbrovaTraceLogger.setLogHandler((level, message, error, stackTrace) {
        called = true;
      });

      AbrovaTraceLogger.setEnabled(false);
      AbrovaTraceLogger.info('test');

      expect(called, isFalse);
    });

    test('calls custom handler when enabled', () {
      AbrovaTraceLogLevel? capturedLevel;
      String? capturedMessage;

      AbrovaTraceLogger.setLogHandler((level, message, error, stackTrace) {
        capturedLevel = level;
        capturedMessage = message;
      });
      AbrovaTraceLogger.setEnabled(true);

      AbrovaTraceLogger.info('Test message');

      expect(capturedLevel, AbrovaTraceLogLevel.info);
      expect(capturedMessage, 'Test message');
    });

    test('debug logs with debug level', () {
      AbrovaTraceLogLevel? capturedLevel;
      AbrovaTraceLogger.setLogHandler((level, message, error, stackTrace) {
        capturedLevel = level;
      });
      AbrovaTraceLogger.setEnabled(true);

      AbrovaTraceLogger.debug('debug msg');
      expect(capturedLevel, AbrovaTraceLogLevel.debug);
    });

    test('warning logs with warning level and optional error', () {
      AbrovaTraceLogLevel? capturedLevel;
      Object? capturedError;

      AbrovaTraceLogger.setLogHandler((level, message, error, stackTrace) {
        capturedLevel = level;
        capturedError = error;
      });
      AbrovaTraceLogger.setEnabled(true);

      final testError = Exception('test error');
      AbrovaTraceLogger.warning('warn msg', testError);

      expect(capturedLevel, AbrovaTraceLogLevel.warning);
      expect(capturedError, testError);
    });

    test('error logs with error level, error, and stack trace', () {
      AbrovaTraceLogLevel? capturedLevel;
      Object? capturedError;
      StackTrace? capturedStack;

      AbrovaTraceLogger.setLogHandler((level, message, error, stackTrace) {
        capturedLevel = level;
        capturedError = error;
        capturedStack = stackTrace;
      });
      AbrovaTraceLogger.setEnabled(true);

      final testError = Exception('critical');
      final testStack = StackTrace.current;
      AbrovaTraceLogger.error('error msg', testError, testStack);

      expect(capturedLevel, AbrovaTraceLogLevel.error);
      expect(capturedError, testError);
      expect(capturedStack, testStack);
    });

    test('multiple log calls are captured', () {
      final messages = <String>[];
      AbrovaTraceLogger.setLogHandler((level, message, error, stackTrace) {
        messages.add(message);
      });
      AbrovaTraceLogger.setEnabled(true);

      AbrovaTraceLogger.debug('msg1');
      AbrovaTraceLogger.info('msg2');
      AbrovaTraceLogger.warning('msg3');
      AbrovaTraceLogger.error('msg4');

      expect(messages, ['msg1', 'msg2', 'msg3', 'msg4']);
    });

    test('setting handler to null removes it', () {
      var callCount = 0;
      AbrovaTraceLogger.setLogHandler((level, message, error, stackTrace) {
        callCount++;
      });
      AbrovaTraceLogger.setEnabled(true);

      AbrovaTraceLogger.info('before');
      expect(callCount, 1);

      AbrovaTraceLogger.setLogHandler(null);
      AbrovaTraceLogger.info('after');
      // No error thrown, handler just not called
      expect(callCount, 1);
    });
  });

  group('AbrovaTraceLogLevel', () {
    test('has all expected levels', () {
      expect(AbrovaTraceLogLevel.values, containsAll([
        AbrovaTraceLogLevel.debug,
        AbrovaTraceLogLevel.info,
        AbrovaTraceLogLevel.warning,
        AbrovaTraceLogLevel.error,
      ]));
    });
  });
}
