import 'session_store.dart';

SessionStore createSessionStore() => MemorySessionStore();

/// Keeps the state in memory only (platforms without files or localStorage, and tests).
class MemorySessionStore implements SessionStore {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String json) async => _value = json;
}
