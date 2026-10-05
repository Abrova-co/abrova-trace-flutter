import 'package:flutter_test/flutter_test.dart';
import 'package:abrova_trace_flutter_sdk/abrova_trace_flutter_sdk.dart';
import 'package:abrova_trace_flutter_sdk/src/models/breadcrumb.dart';

void main() {
  group('AbrovaTraceBreadcrumbs', () {
    setUp(() {
      AbrovaTraceBreadcrumbs.clear();
      AbrovaTraceBreadcrumbs.setMaxBreadcrumbs(20);
    });

    test('starts with empty breadcrumbs', () {
      expect(AbrovaTraceBreadcrumbs.getBreadcrumbs(), isEmpty);
    });

    test('adds a breadcrumb', () {
      AbrovaTraceBreadcrumbs.add('Test crumb');

      final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
      expect(crumbs.length, 1);
      expect(crumbs.first.message, 'Test crumb');
      expect(crumbs.first.type, BreadcrumbType.info); // default type
    });

    test('adds breadcrumb with type and data', () {
      AbrovaTraceBreadcrumbs.add(
        'Button pressed',
        type: BreadcrumbType.user,
        data: {'button': 'submit'},
      );

      final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
      expect(crumbs.first.type, BreadcrumbType.user);
      expect(crumbs.first.data, {'button': 'submit'});
    });

    test('addNavigation creates navigation breadcrumb', () {
      AbrovaTraceBreadcrumbs.addNavigation('/home', '/settings');

      final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
      expect(crumbs.first.type, BreadcrumbType.navigation);
      expect(crumbs.first.message, 'Navigated from /home to /settings');
      expect(crumbs.first.data, {'from': '/home', 'to': '/settings'});
    });

    test('addUser creates user breadcrumb', () {
      AbrovaTraceBreadcrumbs.addUser('clicked login', data: {'page': 'auth'});

      final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
      expect(crumbs.first.type, BreadcrumbType.user);
      expect(crumbs.first.message, 'User clicked login');
      expect(crumbs.first.data, {'page': 'auth'});
    });

    test('addHttp creates HTTP breadcrumb', () {
      AbrovaTraceBreadcrumbs.addHttp('GET', 'https://api.com/users', 200);

      final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
      expect(crumbs.first.type, BreadcrumbType.http);
      expect(crumbs.first.message, contains('GET'));
      expect(crumbs.first.message, contains('https://api.com/users'));
      expect(crumbs.first.data!['method'], 'GET');
      expect(crumbs.first.data!['status_code'], 200);
    });

    test('addHttp handles null statusCode', () {
      AbrovaTraceBreadcrumbs.addHttp('POST', 'https://api.com/data', null);

      final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
      expect(crumbs.first.data!.containsKey('status_code'), isFalse);
    });

    test('addState creates state breadcrumb', () {
      AbrovaTraceBreadcrumbs.addState(
        'Auth state changed',
        data: {'authenticated': true},
      );

      final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
      expect(crumbs.first.type, BreadcrumbType.state);
      expect(crumbs.first.message, 'State: Auth state changed');
    });

    test('addSystem creates system breadcrumb', () {
      AbrovaTraceBreadcrumbs.addSystem(
        'SDK initialized',
        data: {'version': '1.0.0'},
      );

      final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
      expect(crumbs.first.type, BreadcrumbType.system);
      expect(crumbs.first.message, 'SDK initialized');
    });

    test('addError creates error breadcrumb', () {
      AbrovaTraceBreadcrumbs.addError(
        'Exception occurred',
        data: {'type': 'FormatException'},
      );

      final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
      expect(crumbs.first.type, BreadcrumbType.error);
      expect(crumbs.first.message, 'Exception occurred');
    });

    test('respects max breadcrumbs limit', () {
      AbrovaTraceBreadcrumbs.setMaxBreadcrumbs(3);

      AbrovaTraceBreadcrumbs.add('first');
      AbrovaTraceBreadcrumbs.add('second');
      AbrovaTraceBreadcrumbs.add('third');
      AbrovaTraceBreadcrumbs.add('fourth');

      final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
      expect(crumbs.length, 3);
      // Oldest should be removed
      expect(crumbs[0].message, 'second');
      expect(crumbs[1].message, 'third');
      expect(crumbs[2].message, 'fourth');
    });

    test('setMaxBreadcrumbs trims existing breadcrumbs', () {
      for (var i = 0; i < 10; i++) {
        AbrovaTraceBreadcrumbs.add('crumb $i');
      }

      expect(AbrovaTraceBreadcrumbs.getBreadcrumbs().length, 10);

      AbrovaTraceBreadcrumbs.setMaxBreadcrumbs(5);
      expect(AbrovaTraceBreadcrumbs.getBreadcrumbs().length, 5);
      // Should keep the most recent 5
      expect(AbrovaTraceBreadcrumbs.getBreadcrumbs().first.message, 'crumb 5');
    });

    test('clear removes all breadcrumbs', () {
      AbrovaTraceBreadcrumbs.add('one');
      AbrovaTraceBreadcrumbs.add('two');
      expect(AbrovaTraceBreadcrumbs.getBreadcrumbs().length, 2);

      AbrovaTraceBreadcrumbs.clear();
      expect(AbrovaTraceBreadcrumbs.getBreadcrumbs(), isEmpty);
    });

    test('getBreadcrumbs returns unmodifiable list', () {
      AbrovaTraceBreadcrumbs.add('test');
      final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();

      expect(
        () => crumbs.add(Breadcrumb(
          message: 'hack',
          type: BreadcrumbType.info,
          timestamp: DateTime.now(),
        )),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('getBreadcrumbsJson returns serialized breadcrumbs', () {
      AbrovaTraceBreadcrumbs.add(
        'test crumb',
        type: BreadcrumbType.error,
        data: {'key': 'val'},
      );

      final json = AbrovaTraceBreadcrumbs.getBreadcrumbsJson();
      expect(json.length, 1);
      expect(json[0]['message'], 'test crumb');
      expect(json[0]['type'], 'error');
      expect(json[0]['data'], {'key': 'val'});
      expect(json[0].containsKey('timestamp'), isTrue);
    });

    test('getBreadcrumbsString returns formatted debug string', () {
      AbrovaTraceBreadcrumbs.add('crumb 1', type: BreadcrumbType.info);
      AbrovaTraceBreadcrumbs.add('crumb 2', type: BreadcrumbType.error);

      final str = AbrovaTraceBreadcrumbs.getBreadcrumbsString();
      expect(str, contains('[BreadcrumbType.info] crumb 1'));
      expect(str, contains('[BreadcrumbType.error] crumb 2'));
    });
  });
}
