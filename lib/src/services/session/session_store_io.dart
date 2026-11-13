import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'session_store.dart';

SessionStore createSessionStore() => _FileSessionStore();

class _FileSessionStore implements SessionStore {
  static const _name = 'abrova_trace_session.json';
  File? _file;

  Future<File> _open() async =>
      _file ??= File('${(await getApplicationSupportDirectory()).path}/$_name');

  @override
  Future<String?> read() async {
    final file = await _open();
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String json) async {
    final file = await _open();
    await file.parent.create(recursive: true);
    // Write next to it, then rename: a crash in the middle never leaves half a file.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(json, flush: true);
    await tmp.rename(file.path);
  }
}
