/// Base exception for all network-related errors.
///
/// Every failure in the network layer produces a typed subclass of this
/// exception. It is **not** thrown — instead it is attached to
/// [NetworkResponse.exception] so consumers can pattern-match:
///
/// ```dart
/// if (response.exception is NoConnectionException) { ... }
/// ```
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const NetworkException(
    this.message, {
    this.statusCode,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => '$runtimeType(statusCode: $statusCode, message: $message)';
}

/// Request timed out (connect, send, or receive).
class NetworkTimeoutException extends NetworkException {
  const NetworkTimeoutException(
    super.message, {
    super.statusCode,
    super.originalError,
    super.stackTrace,
  });
}

/// Device has no internet connection (SocketException, DNS failure, etc.).
class NoConnectionException extends NetworkException {
  const NoConnectionException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// Server returned 401 and token refresh failed or was not possible.
class UnauthorizedException extends NetworkException {
  const UnauthorizedException(
    super.message, {
    super.originalError,
    super.stackTrace,
  }) : super(statusCode: 401);
}

/// Server returned a 4xx status code (excluding 401 and 429).
class ClientException extends NetworkException {
  const ClientException(
    super.message, {
    required int super.statusCode,
    super.originalError,
    super.stackTrace,
  });
}

/// Server returned a 5xx status code.
class ServerException extends NetworkException {
  const ServerException(
    super.message, {
    required int super.statusCode,
    super.originalError,
    super.stackTrace,
  });
}

/// Server returned 429 Too Many Requests.
///
/// [retryAfter] contains the parsed `Retry-After` header value if present.
class RateLimitException extends NetworkException {
  final Duration? retryAfter;

  const RateLimitException(
    super.message, {
    this.retryAfter,
    super.originalError,
    super.stackTrace,
  }) : super(statusCode: 429);
}

/// JSON decoding failed, or the user-provided [parser] callback threw.
///
/// [rawBody] preserves the original response body for debugging.
class ParseException extends NetworkException {
  final dynamic rawBody;

  const ParseException(
    super.message, {
    this.rawBody,
    super.originalError,
    super.stackTrace,
  });
}

/// The request was explicitly cancelled via a [CancelToken].
class RequestCancelledException extends NetworkException {
  const RequestCancelledException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}

/// SSL/TLS certificate validation failed (bad certificate, expired, etc.).
class SslException extends NetworkException {
  const SslException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });
}
