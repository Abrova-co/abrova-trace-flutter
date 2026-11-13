import 'package:web/web.dart' as web;

import 'session_store.dart';

SessionStore createSessionStore() => _WebSessionStore();

class _WebSessionStore implements SessionStore {
  static const _key = 'abrova_trace_session';

  @override
  Future<String?> read() async {
    try {
      return web.window.localStorage.getItem(_key);
    } catch (_) {
      return null; // storage blocked (private mode, settings)
    }
  }

  @override
  Future<void> write(String json) async {
    try {
      web.window.localStorage.setItem(_key, json);
    } catch (_) {}
  }
}
