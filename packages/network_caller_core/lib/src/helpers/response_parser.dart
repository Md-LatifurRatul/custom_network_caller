import 'dart:convert';

import 'package:network_caller_core/src/config/network_config.dart';
import 'package:network_caller_core/src/config/retry_policy.dart';
import 'package:network_caller_core/src/exceptions/network_exception.dart';
import 'package:network_caller_core/src/models/error_response.dart';
import 'package:network_caller_core/src/models/network_response.dart';

/// Shared response parsing logic used by both HTTP and Dio implementations.
///
/// This avoids duplicating the decode → unwrap → parse → build response
/// pipeline in each caller.
class ResponseParser {
  final NetworkConfig _config;

  const ResponseParser(this._config);

  /// Parses a raw HTTP response into a typed [NetworkResponse].
  ///
  /// [statusCode] — HTTP status code.
  /// [body] — Already-decoded body (Map/List for JSON, String for plain, bytes for binary).
  /// [parser] — User-provided model parser (nullable).
  /// [responseHeaders] — Response headers map.
  /// [reasonPhrase] — HTTP reason phrase (e.g., "Not Found") for fallback messages.
  NetworkResponse<T> parse<T>({
    required int statusCode,
    required dynamic body,
    T Function(dynamic json)? parser,
    Map<String, String>? responseHeaders,
    String? reasonPhrase,
  }) {
    final isSuccess = _config.isSuccessStatus(statusCode);

    if (isSuccess) {
      return _buildSuccess<T>(
        statusCode: statusCode,
        body: body,
        parser: parser,
        responseHeaders: responseHeaders,
      );
    } else {
      return _buildFailure<T>(
        statusCode: statusCode,
        body: body,
        responseHeaders: responseHeaders,
        reasonPhrase: reasonPhrase,
      );
    }
  }

  /// Builds a success [NetworkResponse] from decoded body.
  NetworkResponse<T> _buildSuccess<T>({
    required int statusCode,
    required dynamic body,
    T Function(dynamic json)? parser,
    Map<String, String>? responseHeaders,
  }) {
    // Handle 204 No Content
    if (statusCode == 204 || body == null) {
      return NetworkResponse.success(
        statusCode: statusCode,
        responseHeaders: responseHeaders,
      );
    }

    // Unwrap if configured (e.g., extract body['data'] from wrapped APIs)
    dynamic unwrapped = body;
    if (_config.responseUnwrapper != null && body is Map) {
      unwrapped = _config.responseUnwrapper!(body);
    }

    // Extract message
    final message = _extractMessage(body);

    // Apply parser
    T? data;
    if (parser != null) {
      try {
        data = parser(unwrapped);
      } catch (e, st) {
        return NetworkResponse.failure(
          statusCode: statusCode,
          message: 'Failed to parse response',
          responseHeaders: responseHeaders,
          exception: ParseException(
            'Parser callback threw: $e',
            rawBody: body,
            originalError: e,
            stackTrace: st,
          ),
          error: ErrorResponse(
            statusCode: statusCode,
            message: 'Failed to parse response',
            details: body,
          ),
        );
      }
    } else {
      data = unwrapped as T?;
    }

    return NetworkResponse.success(
      statusCode: statusCode,
      message: message,
      data: data,
      responseHeaders: responseHeaders,
    );
  }

  /// Builds a failure [NetworkResponse] with typed exception.
  NetworkResponse<T> _buildFailure<T>({
    required int statusCode,
    required dynamic body,
    Map<String, String>? responseHeaders,
    String? reasonPhrase,
  }) {
    final message = _extractMessage(body) ?? reasonPhrase;

    // Use custom error parser if configured
    final error = _config.errorParser != null
        ? _config.errorParser!(statusCode, body)
        : ErrorResponse(
            statusCode: statusCode,
            message: message,
            details: body,
          );

    // Map status code to typed exception
    final exception = _mapStatusToException(
      statusCode: statusCode,
      message: message ?? 'Request failed',
      responseHeaders: responseHeaders,
    );

    return NetworkResponse.failure(
      statusCode: statusCode,
      message: message,
      error: error,
      exception: exception,
      responseHeaders: responseHeaders,
    );
  }

  /// Extracts a user-facing message from the response body.
  String? _extractMessage(dynamic body) {
    if (_config.messageExtractor != null) {
      return _config.messageExtractor!(body);
    }
    // Default: try body['message']
    if (body is Map && body.containsKey('message')) {
      return body['message']?.toString();
    }
    return null;
  }

  /// Maps an HTTP status code to a typed [NetworkException].
  NetworkException _mapStatusToException({
    required int statusCode,
    required String message,
    Map<String, String>? responseHeaders,
  }) {
    if (statusCode == 401) {
      return UnauthorizedException(message);
    }
    if (statusCode == 429) {
      final retryAfter = RetryPolicy.parseRetryAfter(
        responseHeaders?['retry-after'],
      );
      return RateLimitException(message, retryAfter: retryAfter);
    }
    if (statusCode >= 500) {
      return ServerException(message, statusCode: statusCode);
    }
    return ClientException(message, statusCode: statusCode);
  }

  /// Decodes a raw JSON string into a dynamic value (Map or List).
  ///
  /// Returns the raw string if decoding fails.
  static dynamic decodeJsonBody(String rawBody) {
    if (rawBody.isEmpty) return null;
    try {
      return jsonDecode(rawBody);
    } catch (_) {
      return rawBody;
    }
  }
}
