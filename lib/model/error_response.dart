class ErrorResponse {
  final String? message;
  final int? statusCode;
  final dynamic details;

  ErrorResponse({this.message, this.statusCode, this.details});

  @override
  String toString() =>
      'ErrorResponse(statusCode: $statusCode, message: $message, details: $details)';
}
