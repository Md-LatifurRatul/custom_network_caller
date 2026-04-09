import 'dart:developer' as dev;

import 'package:network_caller_core/src/enums/request_method.dart';

/// Abstract interface for logging network requests and responses.
///
/// Set `logger: ConsoleNetworkLogger()` in [NetworkConfig] to enable
/// debug logging, or implement your own (e.g., for Crashlytics, Sentry).
abstract class NetworkLogger {
  const NetworkLogger();

  /// Called before the request is sent.
  void logRequest(
    RequestMethod method,
    String url, {
    Map<String, String>? headers,
    dynamic body,
  });

  /// Called after a successful response is received.
  void logResponse(
    int? statusCode,
    String url, {
    dynamic body,
    Duration? elapsed,
  });

  /// Called when a request fails (network error, timeout, etc.).
  void logError(String url, {dynamic error, int? statusCode});
}

/// Default logger that prints to the Dart developer console.
///
/// Only logs in debug mode. Respects [prettyPrint] for JSON formatting.
///
/// ```dart
/// NetworkConfig(
///   baseUrl: 'https://api.example.com',
///   logger: const ConsoleNetworkLogger(),
/// )
/// ```
class ConsoleNetworkLogger extends NetworkLogger {
  final bool prettyPrint;
  final bool logHeaders;
  final bool logBody;

  const ConsoleNetworkLogger({
    this.prettyPrint = true,
    this.logHeaders = false,
    this.logBody = true,
  });

  @override
  void logRequest(
    RequestMethod method,
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) {
    final buffer = StringBuffer()..writeln('→ ${method.value} $url');

    if (logHeaders && headers != null && headers.isNotEmpty) {
      buffer.writeln('  Headers: $headers');
    }
    if (logBody && body != null) {
      buffer.writeln('  Body: $body');
    }

    dev.log(buffer.toString().trimRight(), name: 'NetworkCaller');
  }

  @override
  void logResponse(
    int? statusCode,
    String url, {
    dynamic body,
    Duration? elapsed,
  }) {
    final elapsedStr = elapsed != null ? ' (${elapsed.inMilliseconds}ms)' : '';
    final buffer = StringBuffer()..writeln('← $statusCode $url$elapsedStr');

    if (logBody && body != null) {
      final bodyStr = body.toString();
      final truncated = bodyStr.length > 500
          ? '${bodyStr.substring(0, 500)}...'
          : bodyStr;
      buffer.writeln('  Body: $truncated');
    }

    dev.log(buffer.toString().trimRight(), name: 'NetworkCaller');
  }

  @override
  void logError(String url, {dynamic error, int? statusCode}) {
    final statusStr = statusCode != null ? '[$statusCode] ' : '';
    dev.log('✗ $statusStr$url — $error', name: 'NetworkCaller', level: 1000);
  }
}
