import 'package:network_caller_core/src/enums/request_method.dart';

/// Mutable request options that middlewares can modify before the request is sent.
class MiddlewareRequestContext {
  RequestMethod method;
  String url;
  Map<String, String> headers;
  dynamic body;

  MiddlewareRequestContext({
    required this.method,
    required this.url,
    required this.headers,
    this.body,
  });
}

/// Middleware hook for the HTTP implementation.
///
/// Dio has its own `Interceptor` system — this provides equivalent
/// functionality for the `http` package implementation.
///
/// Middlewares run in the order they are added to [NetworkConfig.middlewares].
///
/// ```dart
/// NetworkConfig(
///   baseUrl: 'https://api.example.com',
///   middlewares: [
///     NetworkMiddleware(
///       onRequest: (ctx) async {
///         ctx.headers['X-Tenant-Id'] = '12345';
///       },
///     ),
///   ],
/// )
/// ```
class NetworkMiddleware {
  /// Called before the request is sent. Modify headers, body, or URL.
  final Future<void> Function(MiddlewareRequestContext context)? onRequest;

  /// Called after a successful response. Inspect or log the response.
  final Future<void> Function(int statusCode, dynamic body)? onResponse;

  /// Called on error. Inspect or log the error.
  final Future<void> Function(dynamic error)? onError;

  const NetworkMiddleware({this.onRequest, this.onResponse, this.onError});
}
