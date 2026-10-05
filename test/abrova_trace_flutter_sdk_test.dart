import 'package:flutter_test/flutter_test.dart';
import 'package:abrova_trace_flutter_sdk/abrova_trace_flutter_sdk.dart';
import 'package:abrova_trace_flutter_sdk/src/services/abrova_trace_logger.dart';

void main() {
  // Initialize the test binding so MethodChannel construction in the
  // native plugin wrapper does not throw before our defensive catches run.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AbrovaTrace', () {
    setUp(() async {
      // Reset state between tests
      AbrovaTraceBreadcrumbs.clear();
      AbrovaTraceNavigatorObserver.reset();
      AbrovaTraceLogger.setEnabled(false);
      AbrovaTraceLogger.setLogHandler(null);

      // Close any existing instance
      try {
        if (AbrovaTrace.isInitialized()) {
          await AbrovaTrace.close();
        }
      } catch (_) {}
    });

    tearDown(() async {
      try {
        if (AbrovaTrace.isInitialized()) {
          await AbrovaTrace.close();
        }
      } catch (_) {}
    });

    group('initialization', () {
      test('isInitialized returns false before init', () {
        expect(AbrovaTrace.isInitialized(), isFalse);
      });

      test('instance throws before init', () {
        expect(
          () => AbrovaTrace.instance,
          throwsA(isA<StateError>()),
        );
      });

      test('init creates an initialized instance', () async {
        await AbrovaTrace.init(const AbrovaTraceConfig(
          apiKey: 'ab_test_1234567890',
          captureUncaughtErrors: false,
          enableOfflineStorage: false,
          debug: false,
        ));

        expect(AbrovaTrace.isInitialized(), isTrue);
      });

      test('getPlatform returns non-null after init', () async {
        await AbrovaTrace.init(const AbrovaTraceConfig(
          apiKey: 'ab_test_1234567890',
          captureUncaughtErrors: false,
          enableOfflineStorage: false,
        ));

        expect(AbrovaTrace.getPlatform(), isNotNull);
      });
    });

    group('user management', () {
      setUp(() async {
        await AbrovaTrace.init(const AbrovaTraceConfig(
          apiKey: 'ab_test_1234567890',
          captureUncaughtErrors: false,
          enableOfflineStorage: false,
        ));
      });

      test('setUserId and getUserId', () {
        AbrovaTrace.setUserId('user-123');
        expect(AbrovaTrace.getUserId(), 'user-123');
      });

      test('getUserId returns null before setting', () {
        expect(AbrovaTrace.getUserId(), isNull);
      });

      test('getSessionId returns non-null after init', () {
        expect(AbrovaTrace.getSessionId(), isNotNull);
        expect(AbrovaTrace.getSessionId()!.length, 32); // 16 bytes hex = 32 chars
      });
    });

    group('extra context', () {
      setUp(() async {
        await AbrovaTrace.init(const AbrovaTraceConfig(
          apiKey: 'ab_test_1234567890',
          captureUncaughtErrors: false,
          enableOfflineStorage: false,
        ));
      });

      test('setExtra and getExtra', () {
        AbrovaTrace.setExtra('app_version', '2.0.0');
        expect(AbrovaTrace.getExtra('app_version'), '2.0.0');
      });

      test('setExtras sets multiple values', () {
        AbrovaTrace.setExtras({
          'device': 'iPhone 15',
          'os': 'iOS 17',
        });
        expect(AbrovaTrace.getExtra('device'), 'iPhone 15');
        expect(AbrovaTrace.getExtra('os'), 'iOS 17');
      });

      test('getExtras returns all extra context', () {
        AbrovaTrace.setExtra('key1', 'val1');
        AbrovaTrace.setExtra('key2', 'val2');

        final extras = AbrovaTrace.getExtras();
        expect(extras, isNotNull);
        expect(extras!['key1'], 'val1');
        expect(extras['key2'], 'val2');
      });

      test('clearExtras removes all context', () {
        AbrovaTrace.setExtra('key', 'val');
        AbrovaTrace.clearExtras();

        expect(AbrovaTrace.getExtra('key'), isNull);
      });
    });

    group('tags', () {
      setUp(() async {
        await AbrovaTrace.init(const AbrovaTraceConfig(
          apiKey: 'ab_test_1234567890',
          captureUncaughtErrors: false,
          enableOfflineStorage: false,
        ));
      });

      test('setTag and getTag', () {
        AbrovaTrace.setTag('module', 'auth');
        expect(AbrovaTrace.getTag('module'), 'auth');
      });

      test('setTags sets multiple tags', () {
        AbrovaTrace.setTags({'env': 'test', 'region': 'us-east'});
        expect(AbrovaTrace.getTag('env'), 'test');
        expect(AbrovaTrace.getTag('region'), 'us-east');
      });

      test('getTags returns all tags', () {
        AbrovaTrace.setTag('a', '1');
        AbrovaTrace.setTag('b', '2');

        final tags = AbrovaTrace.getTags();
        expect(tags, {'a': '1', 'b': '2'});
      });

      test('clearTags removes all tags', () {
        AbrovaTrace.setTag('key', 'val');
        AbrovaTrace.clearTags();
        expect(AbrovaTrace.getTag('key'), isNull);
      });
    });

    group('breadcrumb methods', () {
      setUp(() async {
        await AbrovaTrace.init(const AbrovaTraceConfig(
          apiKey: 'ab_test_1234567890',
          captureUncaughtErrors: false,
          enableOfflineStorage: false,
        ));
        AbrovaTraceBreadcrumbs.clear();
      });

      test('addBreadcrumb adds a breadcrumb', () {
        AbrovaTrace.addBreadcrumb('test', data: {'key': 'val'});

        final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
        expect(crumbs.length, 1);
        expect(crumbs.first.message, 'test');
      });

      test('addNavigationBreadcrumb adds navigation crumb', () {
        AbrovaTrace.addNavigationBreadcrumb('/home', '/settings');

        final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
        expect(crumbs.first.type, BreadcrumbType.navigation);
      });

      test('addUserBreadcrumb adds user action crumb', () {
        AbrovaTrace.addUserBreadcrumb('tapped button');

        final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
        expect(crumbs.first.type, BreadcrumbType.user);
      });

      test('addHttpBreadcrumb adds HTTP crumb', () {
        AbrovaTrace.addHttpBreadcrumb('POST', 'https://api.com', statusCode: 201);

        final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
        expect(crumbs.first.type, BreadcrumbType.http);
      });

      test('clearBreadcrumbs clears all', () {
        AbrovaTrace.addBreadcrumb('one');
        AbrovaTrace.addBreadcrumb('two');
        AbrovaTrace.clearBreadcrumbs();

        expect(AbrovaTraceBreadcrumbs.getBreadcrumbs(), isEmpty);
      });
    });

    group('captureException', () {
      setUp(() async {
        await AbrovaTrace.init(const AbrovaTraceConfig(
          apiKey: 'ab_test_1234567890',
          captureUncaughtErrors: false,
          enableOfflineStorage: false,
        ));
      });

      test('calls callback with false when SDK is disabled', () async {
        await AbrovaTrace.close();
        await AbrovaTrace.init(const AbrovaTraceConfig(
          apiKey: 'ab_test_1234567890',
          captureUncaughtErrors: false,
          enableOfflineStorage: false,
          enabled: false,
        ));

        bool? result;
        await AbrovaTrace.captureException(
          Exception('test'),
          callback: (success) => result = success,
        );

        expect(result, isFalse);
      });
    });

    group('captureMessage', () {
      setUp(() async {
        await AbrovaTrace.init(const AbrovaTraceConfig(
          apiKey: 'ab_test_1234567890',
          captureUncaughtErrors: false,
          enableOfflineStorage: false,
        ));
      });

      test('calls callback with false when SDK is disabled', () async {
        await AbrovaTrace.close();
        await AbrovaTrace.init(const AbrovaTraceConfig(
          apiKey: 'ab_test_1234567890',
          captureUncaughtErrors: false,
          enableOfflineStorage: false,
          enabled: false,
        ));

        bool? result;
        await AbrovaTrace.captureMessage(
          'test message',
          callback: (success) => result = success,
        );

        expect(result, isFalse);
      });
    });

    group('close', () {
      test('resets state after close', () async {
        await AbrovaTrace.init(const AbrovaTraceConfig(
          apiKey: 'ab_test_1234567890',
          captureUncaughtErrors: false,
          enableOfflineStorage: false,
        ));

        expect(AbrovaTrace.isInitialized(), isTrue);

        await AbrovaTrace.close();

        expect(AbrovaTrace.isInitialized(), isFalse);
      });
    });
  });
}
