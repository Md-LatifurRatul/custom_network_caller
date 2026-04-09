import 'package:dio/dio.dart';
import 'package:network_caller_core/network_caller_core.dart';

/// Dio interceptor that forwards request/response/error events
/// to a [NetworkLogger] instance.
///
/// Added automatically when [NetworkConfig.logger] is non-null.
class LoggingInterceptor extends Interceptor {
  final NetworkLogger _logger;

  LoggingInterceptor(this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = RequestMethod.values.firstWhere(
      (m) => m.value == options.method.toUpperCase(),
      orElse: () => RequestMethod.get,
    );

    _logger.logRequest(
      method,
      options.uri.toString(),
      headers: options.headers.map((k, v) => MapEntry(k, v.toString())),
      body: options.data,
    );

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.logResponse(
      response.statusCode,
      response.requestOptions.uri.toString(),
      body: response.data,
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.logError(
      err.requestOptions.uri.toString(),
      error: err.message ?? err.type.name,
      statusCode: err.response?.statusCode,
    );

    handler.next(err);
  }
}
