import 'package:dio/dio.dart';
import 'package:network_call/model/network_response.dart';
import 'package:network_call/services/network/network_config.dart';
import 'package:network_call/services/network/network_interface.dart';
import 'token_interceptor_dio.dart';

class DioNetworkCaller implements NetworkInterface {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: NetworkConfig.baseUrl,
      connectTimeout: NetworkConfig.timeout,
      receiveTimeout: NetworkConfig.timeout,
      headers: NetworkConfig.defaultHeaders,
    ),
  );

  DioNetworkCaller() {
    _dio.interceptors.add(TokenInterceptorDio(_dio));
  }

  @override
  Future<NetworkResponse<T>> getRequest<T>({
    required String url,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final mergedHeaders = {
        ...await NetworkConfig.getHeaders(withToken: withToken),
        ...?headers,
      };

      final response = await _dio.get(
        url,
        options: Options(headers: mergedHeaders),
      );
      return _handleResponse(response, parser);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  @override
  Future<NetworkResponse<T>> postRequest<T>({
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final mergedHeaders = {
        ...await NetworkConfig.getHeaders(withToken: withToken),
        ...?headers,
      };

      final response = await _dio.post(
        url,
        data: body,
        options: Options(headers: mergedHeaders),
      );
      return _handleResponse(response, parser);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  NetworkResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic json)? parser,
  ) {
    final isSuccess =
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300;

    final data = response.data;
    return NetworkResponse(
      isSuccess: isSuccess,
      statusCode: response.statusCode,
      message: data is Map && data.containsKey('message')
          ? data['message']
          : response.statusMessage,
      data: parser != null ? parser(data) : data,
    );
  }

  NetworkResponse<T> _handleError<T>(DioException e) {
    return NetworkResponse(
      isSuccess: false,
      statusCode: e.response?.statusCode,
      message: e.message,
    );
  }
}
