class NetworkResponse<T> {
  final bool isSuccess;
  final int? statusCode;
  final String? message;
  final T? data;

  const NetworkResponse({
    required this.isSuccess,
    this.statusCode,
    this.message,
    this.data,
  });
}
