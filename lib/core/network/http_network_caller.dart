import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:network_call/core/network/network_config.dart';
import 'package:network_call/core/network/network_interface.dart';
import 'package:network_call/model/error_response.dart';
import 'package:network_call/model/network_response.dart';
import 'package:network_call/model/token_manager.dart';

class HttpNetworkCaller implements NetworkInterface {
  final Duration _timeout = NetworkConfig.timeout;

  @override
  Future<NetworkResponse<T>> getRequest<T>({
    required String url,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
  }) => _request<T>(
    method: 'GET',
    url: url,
    withToken: withToken,
    headers: headers,
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
    withToken: withToken,
    headers: headers,
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
    withToken: withToken,
    headers: headers,
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
    withToken: withToken,
    headers: headers,
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
    withToken: withToken,
    headers: headers,
    parser: parser,
  );

  Future<NetworkResponse<T>> _request<T>({
    required String method,
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
    int retryCount = 1,
  }) async {
    try {
      final mergedHeaders = {
        ...await NetworkConfig.getHeaders(withToken: withToken),
        ...?headers,
      };

      final uri = Uri.parse(url);
      http.Response response;
      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: mergedHeaders)
              .timeout(_timeout);
          break;
        case 'POST':
          response = await http
              .post(
                uri,
                headers: mergedHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await http
              .put(
                uri,
                headers: mergedHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
          break;
        case 'PATCH':
          response = await http
              .patch(
                uri,
                headers: mergedHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: mergedHeaders)
              .timeout(_timeout);
          break;
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }

      if (response.statusCode == 401 && retryCount > 0) {
        // Try refresh token flow and retry once
        final refreshed = await _tryRefreshTokenHttp();
        if (refreshed) {
          return _request<T>(
            method: method,
            url: url,
            body: body,
            headers: headers,
            withToken: withToken,
            parser: parser,
            retryCount: retryCount - 1,
          );
        } else {
          await NetworkConfig.clearTokensAndLogout();
        }
      }

      return _handleResponse<T>(response, parser);
    } on SocketException {
      return NetworkResponse(
        isSuccess: false,
        message: 'No internet connection',
        error: ErrorResponse(message: 'No internet connection'),
      );
    } on TimeoutException {
      return NetworkResponse(
        isSuccess: false,
        message: 'Request timeout',
        error: ErrorResponse(message: 'Request timeout'),
      );
    } catch (e, st) {
      return NetworkResponse(
        isSuccess: false,
        message: e.toString(),
        error: ErrorResponse(message: e.toString(), details: st.toString()),
      );
    }
  }

  NetworkResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json)? parser,
  ) {
    final int statusCode = response.statusCode;
    final bool isSuccess = statusCode >= 200 && statusCode < 300;

    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = response.body;
    }

    if (isSuccess) {
      return NetworkResponse(
        isSuccess: true,
        statusCode: statusCode,
        message: decoded is Map && decoded.containsKey('message')
            ? decoded['message']
            : null,
        data: parser != null ? parser(decoded) : decoded,
      );
    } else {
      return NetworkResponse(
        isSuccess: false,
        statusCode: statusCode,
        message: decoded is Map && decoded.containsKey('message')
            ? decoded['message']
            : response.reasonPhrase,
        error: ErrorResponse(
          statusCode: statusCode,
          message: decoded is Map && decoded.containsKey('message')
              ? decoded['message']
              : response.reasonPhrase,
          details: decoded,
        ),
      );
    }
  }

  /// Attempt refresh token using refreshEndpoint. Returns true if refresh succeeded.
  Future<bool> _tryRefreshTokenHttp() async {
    try {
      final refreshToken = await TokenManager.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final url = '${NetworkConfig.baseUrl}${NetworkConfig.refreshEndpoint}';
      final headers = await NetworkConfig.getHeaders(withToken: false);
      final resp = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(_timeout);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        final newAccess = data['access_token'] as String?;
        final newRefresh = data['refresh_token'] as String?;
        if (newAccess != null) {
          await TokenManager.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
