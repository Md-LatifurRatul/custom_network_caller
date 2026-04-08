import 'package:dio/dio.dart';
import 'package:network_call/model/error_response.dart';
import 'package:network_call/model/network_response.dart';
import 'package:network_call/services/network/network_config.dart';
import 'package:network_call/services/network/network_interface.dart';

import 'token_interceptor_dio.dart';

class DioNetworkCaller implements NetworkInterface {
  final Dio _dio;

  DioNetworkCaller({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: NetworkConfig.baseUrl,
              connectTimeout: NetworkConfig.timeout,
              receiveTimeout: NetworkConfig.timeout,
              headers: NetworkConfig.defaultHeaders,
            ),
          ) {
    _dio.interceptors.add(TokenInterceptorDio(_dio));
  }

  @override
  Future<NetworkResponse<T>> getRequest<T>({
    required String url,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
  }) => _request<T>(
    method: 'GET',
    url: url,
    headers: headers,
    withToken: withToken,
    parser: parser,
  );

  @override
  Future<NetworkResponse<T>> postRequest<T>({
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
  }) => _request<T>(
    method: 'POST',
    url: url,
    body: body,
    headers: headers,
    withToken: withToken,
    parser: parser,
  );

  @override
  Future<NetworkResponse<T>> putRequest<T>({
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
  }) => _request<T>(
    method: 'PUT',
    url: url,
    body: body,
    headers: headers,
    withToken: withToken,
    parser: parser,
  );

  @override
  Future<NetworkResponse<T>> patchRequest<T>({
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
  }) => _request<T>(
    method: 'PATCH',
    url: url,
    body: body,
    headers: headers,
    withToken: withToken,
    parser: parser,
  );

  @override
  Future<NetworkResponse<T>> deleteRequest<T>({
    required String url,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
  }) => _request<T>(
    method: 'DELETE',
    url: url,
    headers: headers,
    withToken: withToken,
    parser: parser,
  );

  Future<NetworkResponse<T>> _request<T>({
    required String method,
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
  }) async {
    try {
      // Merge headers (attaches token if withToken true)
      final mergedHeaders = {
        ...await NetworkConfig.getHeaders(withToken: withToken),
        ...?headers,
      };

      final response = await _dio.request(
        // If `url` is absolute (starts with http), Dio will use it directly.
        url,
        data: body,
        options: Options(method: method, headers: mergedHeaders),
      );

      return _handleResponse<T>(response, parser);
    } on DioException catch (e) {
      // DioException may carry response, message, type
      return _handleError(e);
    } catch (e, st) {
      return NetworkResponse<T>(
        isSuccess: false,
        message: e.toString(),
        error: ErrorResponse(message: e.toString(), details: st.toString()),
      );
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

    if (isSuccess) {
      return NetworkResponse(
        isSuccess: true,
        statusCode: response.statusCode,
        message: data is Map && data.containsKey('message')
            ? data['message']
            : null,
        data: parser != null ? parser(data) : data,
      );
    } else {
      return NetworkResponse(
        isSuccess: false,
        statusCode: response.statusCode,
        message: data is Map && data.containsKey('message')
            ? data['message']
            : response.statusMessage,
        error: ErrorResponse(
          statusCode: response.statusCode,
          message: response.statusMessage,
          details: data,
        ),
      );
    }
  }

  NetworkResponse<T> _handleError<T>(DioException e) {
    final resp = e.response;
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkResponse(
        isSuccess: false,
        message: 'Request timeout',
        error: ErrorResponse(message: 'Request timeout'),
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return NetworkResponse(
        isSuccess: false,
        message: 'No internet connection',
        error: ErrorResponse(message: 'No internet connection'),
      );
    }

    if (resp != null) {
      return NetworkResponse(
        isSuccess: false,
        statusCode: resp.statusCode,
        message: resp.data is Map && resp.data.containsKey('message')
            ? resp.data['message']
            : e.message,
        error: ErrorResponse(
          statusCode: resp.statusCode,
          message: e.message,
          details: resp.data,
        ),
      );
    }

    return NetworkResponse(
      isSuccess: false,
      message: e.message,
      error: ErrorResponse(message: e.message),
    );
  }
}
