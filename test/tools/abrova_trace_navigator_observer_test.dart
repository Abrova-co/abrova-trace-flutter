import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abrova_trace_flutter_sdk/abrova_trace_flutter_sdk.dart';

void main() {
  group('AbrovaTraceNavigatorObserver', () {
    setUp(() {
      AbrovaTraceNavigatorObserver.reset();
      AbrovaTraceNavigatorObserver.clearManualRoute();
      AbrovaTraceBreadcrumbs.clear();
    });

    test('currentRoute is null initially', () {
      expect(AbrovaTraceNavigatorObserver.currentRoute, isNull);
    });

    test('previousRoute is null initially', () {
      expect(AbrovaTraceNavigatorObserver.previousRoute, isNull);
    });

    test('setCurrentRoute sets manual route', () {
      AbrovaTraceNavigatorObserver.setCurrentRoute('/profile');
      expect(AbrovaTraceNavigatorObserver.currentRoute, '/profile');
    });

    test('clearManualRoute falls back to automatic', () {
      AbrovaTraceNavigatorObserver.setCurrentRoute('/manual');
      expect(AbrovaTraceNavigatorObserver.currentRoute, '/manual');

      AbrovaTraceNavigatorObserver.clearManualRoute();
      // Falls back to null since no automatic route has been set
      expect(AbrovaTraceNavigatorObserver.currentRoute, isNull);
    });

    test('timeOnCurrentRoute is null when no route', () {
      expect(AbrovaTraceNavigatorObserver.timeOnCurrentRoute, isNull);
    });

    test('getNavigationContext returns context map', () {
      final context = AbrovaTraceNavigatorObserver.getNavigationContext();

      expect(context, isA<Map<String, dynamic>>());
      expect(context.containsKey('current_route'), isTrue);
      expect(context.containsKey('previous_route'), isTrue);
      expect(context.containsKey('time_on_route_seconds'), isTrue);
      expect(context.containsKey('route_history'), isTrue);
    });

    test('reset clears automatic navigation state', () {
      AbrovaTraceNavigatorObserver.reset();

      expect(AbrovaTraceNavigatorObserver.previousRoute, isNull);
      final context = AbrovaTraceNavigatorObserver.getNavigationContext();
      expect((context['route_history'] as List), isEmpty);
    });

    testWidgets('didPush updates current route', (tester) async {
      final observer = AbrovaTraceNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: const Scaffold(body: Text('Home')),
          routes: {
            '/second': (_) => const Scaffold(body: Text('Second')),
          },
        ),
      );

      // Initial route push
      expect(AbrovaTraceNavigatorObserver.currentRoute, '/');

      // Navigate to second page
      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/second');
      await tester.pumpAndSettle();

      expect(AbrovaTraceNavigatorObserver.currentRoute, '/second');
      expect(AbrovaTraceNavigatorObserver.previousRoute, '/');
    });

    testWidgets('didPop updates route on back navigation', (tester) async {
      final observer = AbrovaTraceNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: const Scaffold(body: Text('Home')),
          routes: {
            '/second': (_) => const Scaffold(body: Text('Second')),
          },
        ),
      );

      // Navigate forward
      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/second');
      await tester.pumpAndSettle();
      expect(AbrovaTraceNavigatorObserver.currentRoute, '/second');

      // Navigate back
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(AbrovaTraceNavigatorObserver.currentRoute, '/');
    });

    testWidgets('adds navigation breadcrumbs on route change', (tester) async {
      final observer = AbrovaTraceNavigatorObserver();
      AbrovaTraceBreadcrumbs.clear();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: const Scaffold(body: Text('Home')),
          routes: {
            '/second': (_) => const Scaffold(body: Text('Second')),
          },
        ),
      );

      // Navigate to second page
      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/second');
      await tester.pumpAndSettle();

      final crumbs = AbrovaTraceBreadcrumbs.getBreadcrumbs();
      // Should have at least the initial route entry and the navigation
      expect(crumbs.isNotEmpty, isTrue);
    });

    test('manual route takes precedence over automatic', () {
      AbrovaTraceNavigatorObserver.setCurrentRoute('/manual-override');
      // Even if automatic would say something else, manual wins
      expect(AbrovaTraceNavigatorObserver.currentRoute, '/manual-override');
    });
  });
}
