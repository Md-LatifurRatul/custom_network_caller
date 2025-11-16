import 'package:network_call/model/network_response.dart';

abstract class NetworkInterface {
  Future<NetworkResponse<T>> getRequest<T>({
    required String url,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
  });

  Future<NetworkResponse<T>> postRequest<T>({
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
  });

  Future<NetworkResponse<T>> putRequest<T>({
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
  });

  Future<NetworkResponse<T>> patchRequest<T>({
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
  });

  Future<NetworkResponse<T>> deleteRequest<T>({
    required String url,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
  });
}
