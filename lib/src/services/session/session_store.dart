import 'session_store_stub.dart'
    if (dart.library.js_interop) 'session_store_web.dart'
    if (dart.library.io) 'session_store_io.dart';

/// Where release health keeps its small state between launches: the install id, the current session, and the reports
/// not sent yet. A file on devices, localStorage on the web.
abstract class SessionStore {
  Future<String?> read();
  Future<void> write(String json);

  factory SessionStore.create() => createSessionStore();
}
