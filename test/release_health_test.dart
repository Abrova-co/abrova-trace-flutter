import 'dart:convert';

import 'package:abrova_trace_flutter_sdk/src/services/session/release_health.dart';
import 'package:abrova_trace_flutter_sdk/src/services/session/session_store_stub.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late DateTime now;
  late List<Map<String, dynamic>> sent;
  late int status;
  late bool offline;
  late MemorySessionStore store;

  MockClient server() => MockClient((req) async {
        if (offline) throw http.ClientException('offline');
        expect(req.url.path, '/api/sessions');
        expect(req.headers['X-API-Key'], 'ab_live_test');
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        sent.addAll((body['sessions'] as List).cast<Map<String, dynamic>>());
        return http.Response('{}', status);
      });

  ReleaseHealth make({bool nativeCrashed = false, String? user}) => ReleaseHealth(
        apiUrl: 'https://trace.test',
        apiKey: 'ab_live_test',
        platform: 'flutter_android',
        environment: 'production',
        release: '1.2.0+5',
        userAgent: 'test',
        userId: () => user,
        store: store,
        client: server(),
        clock: () => now,
        nativeCrashCheck: (since) async => nativeCrashed,
      );

  Future<void> settle(ReleaseHealth h) async {
    await Future<void>.delayed(Duration.zero);
    await h.flush();
  }

  setUp(() {
    now = DateTime.utc(2026, 11, 14, 10);
    sent = [];
    status = 202;
    offline = false;
    store = MemorySessionStore();
  });

  test('one ok report per launch, with a stable install id and nothing personal', () async {
    final a = make();
    await a.start();
    await settle(a);
    expect(sent, hasLength(1));
    expect(sent.single.keys.toSet(), {'sid', 'did', 'status', 'started', 'release', 'environment', 'platform'});
    expect(sent.single['status'], 'ok');
    expect(sent.single['release'], '1.2.0+5');
    expect(sent.single['did'], matches(RegExp(r'^[0-9a-f]{32}$')));

    final b = make(); // the next launch
    await b.start();
    await settle(b);
    expect(sent, hasLength(2));
    expect(sent[1]['did'], sent[0]['did']);
    expect(sent[1]['sid'], isNot(sent[0]['sid']));
  });

  test('an uncaught error reports the session crashed once', () async {
    final h = make(user: 'u-1');
    await h.start();
    await h.markCrashed();
    await h.markCrashed();
    await settle(h);
    expect(sent.map((r) => r['status']), ['ok', 'crashed']);
    expect(sent[1]['sid'], sent[0]['sid']);
    expect(sent[1]['started'], sent[0]['started']);
    expect(sent[1]['userId'], 'u-1');
  });

  test('a native crash of the previous launch is reported at the next one', () async {
    final first = make();
    await first.start();
    await settle(first);
    final next = make(nativeCrashed: true);
    await next.start();
    await settle(next);
    expect(sent.map((r) => r['status']), ['ok', 'crashed', 'ok']);
    expect(sent[1]['sid'], sent[0]['sid']);
    expect(sent[2]['sid'], isNot(sent[0]['sid']));
  });

  test('a previous session already reported crashed is not reported again', () async {
    final first = make();
    await first.start();
    await first.markCrashed();
    await settle(first);
    final next = make(nativeCrashed: true);
    await next.start();
    await settle(next);
    expect(sent.where((r) => r['status'] == 'crashed'), hasLength(1));
  });

  test('a new session after 30 minutes in the background, not after a short one', () async {
    final h = make();
    await h.start();
    final first = h.sessionId;
    h.paused();
    now = now.add(const Duration(minutes: 5));
    await h.resumed();
    expect(h.sessionId, first);
    h.paused();
    now = now.add(const Duration(minutes: 31));
    await h.resumed();
    await settle(h);
    expect(h.sessionId, isNot(first));
    expect(sent.map((r) => r['status']), ['ok', 'ok']);
  });

  test('offline: reports are kept (also across launches) and sent later', () async {
    offline = true;
    final a = make();
    await a.start();
    await settle(a);
    expect(sent, isEmpty);
    final b = make(); // next launch, still offline
    await b.start();
    await settle(b);
    offline = false;
    await b.flush();
    expect(sent, hasLength(2));
    await b.flush(); // nothing left
    expect(sent, hasLength(2));
  });

  test('a server error keeps the reports; a refusal drops them', () async {
    status = 503;
    final h = make();
    await h.start();
    await settle(h);
    expect(sent, isNotEmpty); // tried, answered 503: kept
    sent.clear();
    status = 202;
    await h.flush();
    expect(sent.single['status'], 'ok'); // sent again and accepted
    sent.clear();
    await h.flush();
    expect(sent, isEmpty); // nothing left

    status = 401;
    await h.markCrashed();
    await settle(h);
    await h.flush();
    expect(sent, hasLength(1)); // refused once, not again
  });

  test('a broken stored state starts fresh', () async {
    await store.write('{not json');
    final h = make();
    await h.start();
    await settle(h);
    expect(sent.single['status'], 'ok');
  });

  test('keeps at most 50 waiting reports', () async {
    offline = true;
    for (var i = 0; i < 60; i++) {
      final h = make();
      await h.start();
      await settle(h);
    }
    offline = false;
    final h = make();
    await h.start();
    await settle(h);
    expect(sent.length, ReleaseHealth.maxQueued);
  });
}
