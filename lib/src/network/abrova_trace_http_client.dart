// lib/src/network/abrova_trace_http_client.dart
import 'dart:async';
import 'package:http/http.dart' as http;

import '../services/abrova_trace_breadcrumbs.dart';

/// HTTP client wrapper that automatically tracks HTTP requests as breadcrumbs
///
/// Usage:
/// ```dart
/// final client = AbrovaTraceHttpClient();
/// final response = await client.get(Uri.parse('https://api.example.com/data'));
/// ```
class AbrovaTraceHttpClient extends http.BaseClient {
  final http.Client _inner;
  final bool _captureErrors;
  final Set<String> _excludedHosts;

  /// Create a AbrovaTrace HTTP client
  ///
  /// [inner] - The underlying HTTP client (defaults to http.Client())
  /// [captureErrors] - Whether to capture HTTP errors (4xx, 5xx) as error breadcrumbs
  /// [excludedHosts] - Hosts to exclude from tracking (e.g., your own API)
  AbrovaTraceHttpClient({
    http.Client? inner,
    bool captureErrors = true,
    Set<String>? excludedHosts,
  }) : _inner = inner ?? http.Client(),
       _captureErrors = captureErrors,
       _excludedHosts = excludedHosts ?? {};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stopwatch = Stopwatch()..start();
    final url = _sanitizeUrl(request.url.toString());
    final method = request.method;

    // Skip tracking for excluded hosts
    if (_excludedHosts.contains(request.url.host)) {
      return _inner.send(request);
    }

    // Skip tracking for AbrovaTrace API calls
    if (request.url.host.contains('abrova')) {
      return _inner.send(request);
    }

    try {
      final response = await _inner.send(request);
      stopwatch.stop();

      // Add HTTP breadcrumb
      AbrovaTraceBreadcrumbs.addHttp(method, url, response.statusCode);

      // Track errors if enabled
      if (_captureErrors && response.statusCode >= 400) {
        final errorType = response.statusCode >= 500
            ? 'Server Error'
            : 'Client Error';
        AbrovaTraceBreadcrumbs.addError(
          'HTTP $errorType: $method $url',
          data: {
            'status_code': response.statusCode,
            'duration_ms': stopwatch.elapsedMilliseconds,
            'method': method,
            'url': url,
          },
        );
      }

      return response;
    } catch (e) {
      stopwatch.stop();

      // Add error breadcrumb for network failures
      AbrovaTraceBreadcrumbs.addError(
        'HTTP Request Failed: $method $url',
        data: {
          'error': e.toString(),
          'duration_ms': stopwatch.elapsedMilliseconds,
          'method': method,
          'url': url,
        },
      );

      rethrow;
    }
  }

  /// Sanitize URL by removing sensitive query parameters
  String _sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final sanitizedParams = <String, String>{};

      uri.queryParameters.forEach((key, value) {
        final lowerKey = key.toLowerCase();
        if (_isSensitiveParam(lowerKey)) {
          sanitizedParams[key] = '[REDACTED]';
        } else {
          sanitizedParams[key] = value;
        }
      });

      if (sanitizedParams.isEmpty) {
        return '${uri.scheme}://${uri.host}${uri.path}';
      }

      return uri.replace(queryParameters: sanitizedParams).toString();
    } catch (e) {
      return url;
    }
  }

  bool _isSensitiveParam(String key) {
    const sensitiveParams = [
      'token',
      'api_key',
      'apikey',
      'key',
      'secret',
      'password',
      'pwd',
      'auth',
      'authorization',
      'access_token',
      'refresh_token',
      'session',
      'sessionid',
      'session_id',
      'credential',
      'credentials',
    ];
    return sensitiveParams.any((param) => key.contains(param));
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Extension to easily wrap an existing http.Client with AbrovaTrace tracking
extension AbrovaTraceHttpClientExtension on http.Client {
  /// Wrap this client with AbrovaTrace HTTP tracking
  AbrovaTraceHttpClient withAbrovaTrace({
    bool captureErrors = true,
    Set<String>? excludedHosts,
  }) {
    return AbrovaTraceHttpClient(
      inner: this,
      captureErrors: captureErrors,
      excludedHosts: excludedHosts,
    );
  }
}
