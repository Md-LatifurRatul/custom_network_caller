import 'package:network_caller_core/src/auth/auth_strategy.dart';
import 'package:network_caller_core/src/config/retry_policy.dart';
import 'package:network_caller_core/src/interfaces/network_logger.dart';
import 'package:network_caller_core/src/interfaces/network_middleware.dart';
import 'package:network_caller_core/src/models/error_response.dart';

/// Callback to extract tokens from a refresh endpoint response body.
///
/// Return a record with [accessToken] and optionally [refreshToken].
/// Defaults to reading `body['access_token']` and `body['refresh_token']`.
typedef TokenExtractor =
    ({String? accessToken, String? refreshToken}) Function(
      Map<String, dynamic> body,
    );

/// Extracts a specific field from the response body before passing to the parser.
///
/// Use when your API wraps data: `{"data": {...}, "meta": {...}}`.
/// ```dart
/// responseUnwrapper: (body) => body['data']
/// ```
typedef ResponseUnwrapper = dynamic Function(dynamic body);

/// Extracts the user-facing message from the response body.
///
/// Defaults to `body['message']` if not provided.
typedef MessageExtractor = String? Function(dynamic body);

/// Custom error parser for APIs with non-standard error structures.
///
/// ```dart
/// errorParser: (statusCode, body) => ErrorResponse(
///   statusCode: statusCode,
///   message: body['error']['description'],
///   details: body['error']['fields'],
/// )
/// ```
typedef ErrorParser = ErrorResponse Function(int statusCode, dynamic body);

/// Central configuration for the network caller.
///
/// Only [baseUrl] is required — everything else has a smart default.
///
/// ```dart
/// final config = NetworkConfig(
///   baseUrl: 'https://api.example.com',
///   // All below are optional with sensible defaults:
///   connectTimeout: Duration(seconds: 15),
///   logger: ConsoleNetworkLogger(),
///   retryPolicy: RetryPolicy.standard(),
/// );
/// ```
class NetworkConfig {
  // === REQUIRED ===

  /// Base URL for all requests. Relative URLs are prepended with this.
  final String baseUrl;

  // === HEADERS ===

  /// Default headers sent with every request.
  final Map<String, String> defaultHeaders;

  /// User-Agent header. Auto-added to all requests if non-null.
  final String? userAgent;

  // === TIMEOUTS ===

  /// Maximum time to establish a connection.
  final Duration connectTimeout;

  /// Maximum time to receive the full response.
  final Duration receiveTimeout;

  /// Maximum time to send the request body (uploads). Defaults to [receiveTimeout].
  final Duration? sendTimeout;

  // === AUTH ===

  /// Determines how auth headers are built. Default: [BearerAuthStrategy].
  final AuthStrategy authStrategy;

  /// Endpoint path for token refresh (relative to [baseUrl]).
  final String refreshEndpoint;

  /// Custom extractor for token field names in refresh response.
  /// If null, defaults to `access_token` and `refresh_token` keys.
  final TokenExtractor? tokenExtractor;

  /// Called when token refresh fails and tokens are cleared.
  final Future<void> Function()? onLogout;

  // === RESPONSE HANDLING ===

  /// Extracts the data payload from wrapped API responses before parsing.
  /// Example: `(body) => body['data']` for `{"data": {...}, "meta": {...}}`.
  final ResponseUnwrapper? responseUnwrapper;

  /// Custom message field extractor. Defaults to `body['message']`.
  final MessageExtractor? messageExtractor;

  /// Custom error body parser. If null, uses the default parser.
  final ErrorParser? errorParser;

  /// Custom success status code validator.
  /// Defaults to `(code) => code >= 200 && code < 300`.
  final bool Function(int statusCode)? validateStatus;

  // === RETRY ===

  /// Retry policy for failed requests. Default: no retries.
  final RetryPolicy retryPolicy;

  // === LOGGING ===

  /// Logger for request/response/error logging. Null = no logging (default).
  final NetworkLogger? logger;

  // === BEHAVIOR ===

  /// Whether to follow HTTP redirects. Default: true.
  final bool followRedirects;

  /// Middleware hooks for the HTTP implementation.
  /// For Dio, use `extraInterceptors` on the Dio caller instead.
  final List<NetworkMiddleware> middlewares;

  const NetworkConfig({
    required this.baseUrl,
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    this.userAgent,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.sendTimeout,
    this.authStrategy = const BearerAuthStrategy(),
    this.refreshEndpoint = '/auth/refresh',
    this.tokenExtractor,
    this.onLogout,
    this.responseUnwrapper,
    this.messageExtractor,
    this.errorParser,
    this.validateStatus,
    this.retryPolicy = const RetryPolicy.none(),
    this.logger,
    this.followRedirects = true,
    this.middlewares = const [],
  });

  /// Effective send timeout — falls back to [receiveTimeout] if not set.
  Duration get effectiveSendTimeout => sendTimeout ?? receiveTimeout;

  /// Returns true if the [statusCode] represents a successful response.
  bool isSuccessStatus(int statusCode) {
    if (validateStatus != null) return validateStatus!(statusCode);
    return statusCode >= 200 && statusCode < 300;
  }

  /// Creates a copy with the specified fields replaced.
  NetworkConfig copyWith({
    String? baseUrl,
    Map<String, String>? defaultHeaders,
    String? userAgent,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    AuthStrategy? authStrategy,
    String? refreshEndpoint,
    TokenExtractor? tokenExtractor,
    Future<void> Function()? onLogout,
    ResponseUnwrapper? responseUnwrapper,
    MessageExtractor? messageExtractor,
    ErrorParser? errorParser,
    bool Function(int statusCode)? validateStatus,
    RetryPolicy? retryPolicy,
    NetworkLogger? logger,
    bool? followRedirects,
    List<NetworkMiddleware>? middlewares,
  }) {
    return NetworkConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      userAgent: userAgent ?? this.userAgent,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      authStrategy: authStrategy ?? this.authStrategy,
      refreshEndpoint: refreshEndpoint ?? this.refreshEndpoint,
      tokenExtractor: tokenExtractor ?? this.tokenExtractor,
      onLogout: onLogout ?? this.onLogout,
      responseUnwrapper: responseUnwrapper ?? this.responseUnwrapper,
      messageExtractor: messageExtractor ?? this.messageExtractor,
      errorParser: errorParser ?? this.errorParser,
      validateStatus: validateStatus ?? this.validateStatus,
      retryPolicy: retryPolicy ?? this.retryPolicy,
      logger: logger ?? this.logger,
      followRedirects: followRedirects ?? this.followRedirects,
      middlewares: middlewares ?? this.middlewares,
    );
  }
}
