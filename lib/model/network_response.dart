import 'package:network_call/model/error_response.dart';

class NetworkResponse<T> {
  final bool isSuccess;
  final int? statusCode;
  final String? message;
  final T? data;
  final ErrorResponse? error;

  const NetworkResponse({
    required this.isSuccess,
    this.statusCode,
    this.message,
    this.data,
    this.error,
  });

  @override
  String toString() =>
      'NetworkResponse(isSuccess: $isSuccess, statusCode: $statusCode, message: $message, data: $data, error: $error)';
}
