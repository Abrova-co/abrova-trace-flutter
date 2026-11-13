import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../abrova_trace_logger.dart';
import 'session_store.dart';

/// Asks the native side whether the app's process ended in a native crash after [sinceMs] (Android: the exit
/// reasons, iOS: a pending crash report). False when unknown.
typedef NativeCrashCheck = Future<bool> Function(int sinceMs);

/// Release health: one session per app launch, and a new one after [backgroundTimeout] in the background. Each session
/// is reported once as `ok` when it starts and once more as `crashed` when it crashed: an uncaught error at once, a
/// native crash at the next launch. Abrova Trace counts every session and crash once, so a report may be sent again.
///
/// Sends only a random install id (made on the device, never a device id), a random session id, the start time, the
/// release, the environment, the platform and the user id the app set. Reports that could not be sent are kept and
/// sent later (at most [maxQueued]).
class ReleaseHealth {
  ReleaseHealth({
    required this.apiUrl,
    required this.apiKey,
    required this.platform,
    required this.environment,
    required this.release,
    required this.userAgent,
    required this.userId,
    SessionStore? store,
    http.Client? client,
    NativeCrashCheck? nativeCrashCheck,
    DateTime Function()? clock,
    this.timeout = const Duration(seconds: 30),
    this.backgroundTimeout = const Duration(minutes: 30),
  })  : _store = store ?? SessionStore.create(),
        _client = client ?? http.Client(),
        _nativeCrashCheck = nativeCrashCheck,
        _clock = clock ?? DateTime.now;

  final String apiUrl;
  final String apiKey;
  final String platform;
  final String environment;
  final String? release;
  final String userAgent;
  final String? Function() userId;
  final Duration timeout;
  final Duration backgroundTimeout;

  static const int maxQueued = 50;

  final SessionStore _store;
  final http.Client _client;
  final NativeCrashCheck? _nativeCrashCheck;
  final DateTime Function() _clock;
  static final Random _random = Random.secure();

  String? _installId;
  Map<String, dynamic>? _current;
  List<Map<String, dynamic>> _queue = [];
  DateTime? _backgroundSince;
  bool _started = false;
  Future<void> _tail = Future.value();

  /// The current session's id, or null before [start].
  String? get sessionId => _current?['sid'] as String?;

  /// Runs state changes one after another (a crash and a resume at the same moment must not overwrite each other).
  Future<T> _serial<T>(Future<T> Function() change) {
    final run = _tail.then((_) => change());
    _tail = run.then((_) {}, onError: (_) {});
    return run;
  }

  static String _id() => List<int>.generate(16, (_) => _random.nextInt(256))
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  /// Starts the first session of this launch. Before that, reports the previous launch's session as crashed when the
  /// native side says the process died in a native crash.
  Future<void> start() => _serial(() async {
        if (_started) return;
        _started = true;
        await _load();
        final previous = _current;
        final check = _nativeCrashCheck;
        if (previous != null && previous['crashed'] != true && check != null) {
          try {
            final since = DateTime.parse(previous['started'] as String).millisecondsSinceEpoch;
            if (await check(since)) {
              previous['crashed'] = true;
              _enqueue(previous, 'crashed');
            }
          } catch (e) {
            AbrovaTraceLogger.debug('Release health: native crash check failed: $e');
          }
        }
        _newSession();
        await _save();
        unawaited(flush());
      });

  /// An uncaught error: the current session crashed (reported once).
  Future<void> markCrashed() => _serial(() async {
        final s = _current;
        if (s == null || s['crashed'] == true) return;
        s['crashed'] = true;
        _enqueue(s, 'crashed');
        await _save();
        unawaited(flush());
      });

  /// The app went to the background.
  void paused() => _backgroundSince = _clock();

  /// The app came back: a new session after [backgroundTimeout] away; reports still waiting are sent.
  Future<void> resumed() => _serial(() async {
        final since = _backgroundSince;
        _backgroundSince = null;
        if (_started && since != null && _clock().difference(since) >= backgroundTimeout) {
          _newSession();
          await _save();
        }
        unawaited(flush());
      });

  bool _flushing = false;

  /// Sends the waiting reports. Kept on a network or server error, dropped when the server refuses them for good.
  Future<void> flush() async {
    if (_flushing || _queue.isEmpty) return;
    _flushing = true;
    try {
      final batch = List<Map<String, dynamic>>.from(_queue);
      final response = await _client
          .post(
            Uri.parse('$apiUrl/api/sessions'),
            headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey, 'User-Agent': userAgent},
            body: jsonEncode({'sessions': batch}),
          )
          .timeout(timeout);
      final code = response.statusCode;
      final done = (code >= 200 && code < 300) || code == 400 || code == 401 || code == 403 || code == 413;
      if (done) {
        await _serial(() async {
          _queue.removeWhere((r) => batch.any((b) => b['sid'] == r['sid'] && b['status'] == r['status']));
          await _save();
        });
        if (code >= 300) AbrovaTraceLogger.warning('Release health reports refused ($code): ${response.body}');
      } else {
        AbrovaTraceLogger.debug('Release health: server answered $code, reports kept');
      }
    } catch (e) {
      AbrovaTraceLogger.debug('Release health: reports kept for later ($e)');
    } finally {
      _flushing = false;
    }
  }

  void _newSession() {
    _current = {
      'sid': _id(),
      'started': _clock().toUtc().toIso8601String(),
      'release': release ?? '',
      'environment': environment,
      'platform': platform,
      'crashed': false,
    };
    _enqueue(_current!, 'ok');
  }

  void _enqueue(Map<String, dynamic> session, String status) {
    final uid = userId();
    _queue.add({
      'sid': session['sid'],
      'did': _installId,
      'status': status,
      'started': session['started'],
      'release': session['release'],
      'environment': session['environment'],
      'platform': session['platform'],
      if (uid != null && uid.isNotEmpty) 'userId': uid,
    });
    if (_queue.length > maxQueued) _queue = _queue.sublist(_queue.length - maxQueued);
  }

  Future<void> _load() async {
    try {
      final raw = await _store.read();
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _installId = data['did'] as String?;
        _current = (data['current'] as Map?)?.cast<String, dynamic>();
        _queue = ((data['queue'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
      }
    } catch (e) {
      AbrovaTraceLogger.debug('Release health: stored state unreadable, starting fresh ($e)');
      _current = null;
      _queue = [];
    }
    final id = _installId;
    if (id == null || !RegExp(r'^[0-9a-f]{32}$').hasMatch(id)) _installId = _id();
  }

  Future<void> _save() async {
    try {
      await _store.write(jsonEncode({'did': _installId, 'current': _current, 'queue': _queue}));
    } catch (e) {
      AbrovaTraceLogger.debug('Release health: state not saved ($e)');
    }
  }
}
