/// Structured error details returned inside [NetworkResponse] on failure.
///
/// Contains the server error [message], HTTP [statusCode], and raw [details]
/// from the response body for debugging or display.
class ErrorResponse {
  final String? message;
  final int? statusCode;
  final dynamic details;

  const ErrorResponse({
    this.message,
    this.statusCode,
    this.details,
  });

  ErrorResponse copyWith({
    String? message,
    int? statusCode,
    dynamic details,
  }) {
    return ErrorResponse(
      message: message ?? this.message,
      statusCode: statusCode ?? this.statusCode,
      details: details ?? this.details,
    );
  }

  @override
  String toString() =>
      'ErrorResponse(statusCode: $statusCode, message: $message, details: $details)';
}
