import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:network_call/model/network_response.dart';
import 'package:network_call/services/network/network_config.dart';
import 'network_interface.dart';

class HttpNetworkCaller implements NetworkInterface {
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

      final response = await http
          .get(Uri.parse(url), headers: mergedHeaders)
          .timeout(NetworkConfig.timeout);

      return _handleResponse<T>(response, parser);
    } catch (e) {
      return NetworkResponse(isSuccess: false, message: e.toString());
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

      final response = await http
          .post(Uri.parse(url), headers: mergedHeaders, body: jsonEncode(body))
          .timeout(NetworkConfig.timeout);

      return _handleResponse<T>(response, parser);
    } catch (e) {
      return NetworkResponse(isSuccess: false, message: e.toString());
    }
  }

  NetworkResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json)? parser,
  ) {
    final statusCode = response.statusCode;
    final isSuccess = statusCode >= 200 && statusCode < 300;

    try {
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      return NetworkResponse(
        isSuccess: isSuccess,
        statusCode: statusCode,
        message: decoded is Map && decoded.containsKey('message')
            ? decoded['message']
            : response.reasonPhrase,
        data: parser != null ? parser(decoded) : decoded,
      );
    } catch (_) {
      return NetworkResponse(
        isSuccess: isSuccess,
        statusCode: statusCode,
        message: response.reasonPhrase,
        data: response.body as T?,
      );
    }
  }
}
