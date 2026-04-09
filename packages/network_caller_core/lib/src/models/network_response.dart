import 'package:network_caller_core/src/exceptions/network_exception.dart';
import 'package:network_caller_core/src/models/error_response.dart';

/// Generic response wrapper for every network call.
///
/// [T] is the parsed data type — a model, `List<Model>`, raw `Map`, `String`,
/// or `List<int>` depending on the [parser] and [ResponseType] used.
///
/// ```dart
/// final res = await caller.get<User>(url: '/profile', parser: User.fromJson);
/// if (res.isSuccess) {
///   final user = res.data!;
/// } else {
///   print(res.exception); // typed NetworkException
/// }
/// ```
class NetworkResponse<T> {
  final bool isSuccess;
  final int? statusCode;
  final String? message;
  final T? data;
  final Map<String, String>? responseHeaders;
  final ErrorResponse? error;
  final NetworkException? exception;

  const NetworkResponse({
    required this.isSuccess,
    this.statusCode,
    this.message,
    this.data,
    this.responseHeaders,
    this.error,
    this.exception,
  });

  /// Creates a success response.
  factory NetworkResponse.success({
    int? statusCode,
    String? message,
    T? data,
    Map<String, String>? responseHeaders,
  }) {
    return NetworkResponse(
      isSuccess: true,
      statusCode: statusCode,
      message: message,
      data: data,
      responseHeaders: responseHeaders,
    );
  }

  /// Creates a failure response.
  factory NetworkResponse.failure({
    int? statusCode,
    String? message,
    ErrorResponse? error,
    NetworkException? exception,
    Map<String, String>? responseHeaders,
  }) {
    return NetworkResponse(
      isSuccess: false,
      statusCode: statusCode ?? exception?.statusCode,
      message: message ?? exception?.message ?? error?.message,
      error: error,
      exception: exception,
      responseHeaders: responseHeaders,
    );
  }

  @override
  String toString() =>
      'NetworkResponse(isSuccess: $isSuccess, statusCode: $statusCode, '
      'message: $message, data: $data, exception: $exception)';
}
