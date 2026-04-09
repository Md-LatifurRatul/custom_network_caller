import 'dart:async';

import 'package:dio/dio.dart' as dio;
import 'package:network_caller_core/network_caller_core.dart';

import 'dio_cancel_token.dart';
import 'logging_interceptor.dart';
import 'token_interceptor.dart';

/// Full [NetworkInterface] implementation using the `dio` package.
///
/// Handles: auth strategies, token refresh via interceptor with Completer lock,
/// retry with exponential backoff, per-request timeout, cancellation,
/// native Dio interceptors, response headers, responseType, multipart uploads,
/// logging, and typed exceptions.
///
/// ```dart
/// final caller = DioNetworkCaller(
///   config: NetworkConfig(baseUrl: 'https://api.example.com'),
///   tokenStorage: SecureTokenStorage(),
/// );
///
/// final res = await caller.get<User>(
///   url: '/profile',
///   withToken: true,
///   parser: (json) => User.fromJson(json),
/// );
/// ```
class DioNetworkCaller implements NetworkInterface {
  final NetworkConfig _config;
  final TokenManager _tokenManager;
  final ResponseParser _parser;
  final dio.Dio _dio;
  bool _disposed = false;

  DioNetworkCaller({
    required NetworkConfig config,
    required TokenStorage tokenStorage,
    dio.Dio? dioInstance,
    List<dio.Interceptor>? extraInterceptors,
  })  : _config = config,
        _tokenManager = TokenManager(tokenStorage),
        _parser = ResponseParser(config),
        _dio = dioInstance ??
            dio.Dio(dio.BaseOptions(
              baseUrl: config.baseUrl,
              connectTimeout: config.connectTimeout,
              receiveTimeout: config.receiveTimeout,
              sendTimeout: config.effectiveSendTimeout,
              headers: config.defaultHeaders,
              followRedirects: config.followRedirects,
            )) {
    // Add token interceptor (handles 401 refresh + retry)
    _dio.interceptors.add(TokenInterceptor(
      dio: _dio,
      tokenManager: _tokenManager,
      config: config,
    ));

    // Add logging interceptor if configured
    if (config.logger != null) {
      _dio.interceptors.add(LoggingInterceptor(config.logger!));
    }

    // Add user-provided interceptors
    if (extraInterceptors != null) {
      _dio.interceptors.addAll(extraInterceptors);
    }
  }

  @override
  NetworkConfig get config => _config;

  /// Provides access to [TokenManager] for saving/clearing tokens after login/logout.
  TokenManager get tokenManager => _tokenManager;

  /// Provides access to the underlying [dio.Dio] instance for advanced usage
  /// (e.g., adding custom interceptors after construction).
  dio.Dio get dioInstance => _dio;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  @override
  Future<NetworkResponse<T>> get<T>({
    required String url,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
    Duration? timeout,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
  }) =>
      _request<T>(
        method: RequestMethod.get,
        url: url,
        queryParameters: queryParameters,
        headers: headers,
        withToken: withToken,
        parser: parser,
        timeout: timeout,
        responseType: responseType,
        cancelToken: cancelToken,
      );

  @override
  Future<NetworkResponse<T>> post<T>({
    required String url,
    dynamic body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
    Duration? timeout,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
  }) =>
      _request<T>(
        method: RequestMethod.post,
        url: url,
        body: body,
        headers: headers,
        withToken: withToken,
        parser: parser,
        timeout: timeout,
        responseType: responseType,
        cancelToken: cancelToken,
      );

  @override
  Future<NetworkResponse<T>> put<T>({
    required String url,
    dynamic body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
    Duration? timeout,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
  }) =>
      _request<T>(
        method: RequestMethod.put,
        url: url,
        body: body,
        headers: headers,
        withToken: withToken,
        parser: parser,
        timeout: timeout,
        responseType: responseType,
        cancelToken: cancelToken,
      );

  @override
  Future<NetworkResponse<T>> patch<T>({
    required String url,
    dynamic body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
    Duration? timeout,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
  }) =>
      _request<T>(
        method: RequestMethod.patch,
        url: url,
        body: body,
        headers: headers,
        withToken: withToken,
        parser: parser,
        timeout: timeout,
        responseType: responseType,
        cancelToken: cancelToken,
      );

  @override
  Future<NetworkResponse<T>> delete<T>({
    required String url,
    dynamic body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
    Duration? timeout,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
  }) =>
      _request<T>(
        method: RequestMethod.delete,
        url: url,
        body: body,
        headers: headers,
        withToken: withToken,
        parser: parser,
        timeout: timeout,
        responseType: responseType,
        cancelToken: cancelToken,
      );

  @override
  Future<NetworkResponse<T>> upload<T>({
    required String url,
    required List<NetworkMultipartFile> files,
    Map<String, String>? fields,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    _throwIfDisposed();

    try {
      final mergedHeaders = await _tokenManager.buildHeaders(
        baseHeaders: _config.defaultHeaders,
        authStrategy: _config.authStrategy,
        userAgent: _config.userAgent,
        withToken: withToken,
        extra: headers,
      );
      // Remove Content-Type — FormData sets its own boundary
      mergedHeaders.remove('Content-Type');

      // Build FormData
      final formData = dio.FormData();

      // Add fields
      if (fields != null) {
        for (final entry in fields.entries) {
          formData.fields.add(MapEntry(entry.key, entry.value));
        }
      }

      // Add files
      for (final file in files) {
        formData.files.add(MapEntry(
          file.field,
          dio.MultipartFile.fromBytes(
            file.bytes,
            filename: file.filename,
          ),
        ));
      }

      final dioCancelToken =
          (cancelToken is DioCancelToken) ? cancelToken.dioToken : null;

      final response = await _dio.post(
        url,
        data: formData,
        options: dio.Options(headers: mergedHeaders),
        cancelToken: dioCancelToken,
        onSendProgress: onProgress,
      );

      final responseHeaders = _extractHeaders(response);
      return _parser.parse<T>(
        statusCode: response.statusCode ?? 0,
        body: response.data,
        parser: parser,
        responseHeaders: responseHeaders,
        reasonPhrase: response.statusMessage,
      );
    } on dio.DioException catch (e) {
      return _mapDioException<T>(e);
    } catch (e, st) {
      return NetworkResponse.failure(
        exception:
            NetworkException(e.toString(), originalError: e, stackTrace: st),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _dio.close();
  }

  // ---------------------------------------------------------------------------
  // Core request pipeline
  // ---------------------------------------------------------------------------

  Future<NetworkResponse<T>> _request<T>({
    required RequestMethod method,
    required String url,
    Map<String, String>? queryParameters,
    dynamic body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
    Duration? timeout,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
    int retryAttempt = 0,
  }) async {
    _throwIfDisposed();

    try {
      // Build headers
      final mergedHeaders = await _tokenManager.buildHeaders(
        baseHeaders: _config.defaultHeaders,
        authStrategy: _config.authStrategy,
        userAgent: _config.userAgent,
        withToken: withToken,
        extra: headers,
      );

      // Build auth query params
      final authQueryParams = await _tokenManager.buildAuthQueryParams(
        authStrategy: _config.authStrategy,
        withToken: withToken,
      );
      final allQueryParams = <String, dynamic>{
        ...?queryParameters,
        ...authQueryParams,
      };

      // Map ResponseType to Dio's ResponseType
      final dioResponseType = _mapResponseType(responseType);

      // Cancel token
      final dioCancelToken =
          (cancelToken is DioCancelToken) ? cancelToken.dioToken : null;

      // Execute request
      final response = await _dio.request<dynamic>(
        url,
        data: body,
        queryParameters: allQueryParams.isEmpty ? null : allQueryParams,
        options: dio.Options(
          method: method.value,
          headers: mergedHeaders,
          sendTimeout: timeout,
          receiveTimeout: timeout,
          responseType: dioResponseType,
          followRedirects: _config.followRedirects,
        ),
        cancelToken: dioCancelToken,
      );

      final statusCode = response.statusCode ?? 0;
      final responseHeaders = _extractHeaders(response);

      // --- Retry Policy (5xx, 429, custom) ---
      // Note: 401 is handled by TokenInterceptor, not here
      if (_config.retryPolicy.shouldRetry(statusCode, retryAttempt)) {
        Duration delay = _config.retryPolicy.delayForAttempt(retryAttempt);
        if (statusCode == 429) {
          final retryAfter =
              RetryPolicy.parseRetryAfter(responseHeaders['retry-after']);
          if (retryAfter != null) delay = retryAfter;
        }

        await Future<void>.delayed(delay);
        return _request<T>(
          method: method,
          url: url,
          queryParameters: queryParameters,
          body: body,
          headers: headers,
          withToken: withToken,
          parser: parser,
          timeout: timeout,
          responseType: responseType,
          cancelToken: cancelToken,
          retryAttempt: retryAttempt + 1,
        );
      }

      // --- Parse response ---
      return _parser.parse<T>(
        statusCode: statusCode,
        body: response.data,
        parser: parser,
        responseHeaders: responseHeaders,
        reasonPhrase: response.statusMessage,
      );
    } on dio.DioException catch (e) {
      // Retry on server errors caught as DioException (e.g., validateStatus)
      final statusCode = e.response?.statusCode;
      if (statusCode != null &&
          _config.retryPolicy.shouldRetry(statusCode, retryAttempt)) {
        final responseHeaders = e.response?.headers.map.map(
                (k, v) => MapEntry(k, v.join(', '))) ??
            {};
        Duration delay = _config.retryPolicy.delayForAttempt(retryAttempt);
        if (statusCode == 429) {
          final retryAfter =
              RetryPolicy.parseRetryAfter(responseHeaders['retry-after']);
          if (retryAfter != null) delay = retryAfter;
        }

        await Future<void>.delayed(delay);
        return _request<T>(
          method: method,
          url: url,
          queryParameters: queryParameters,
          body: body,
          headers: headers,
          withToken: withToken,
          parser: parser,
          timeout: timeout,
          responseType: responseType,
          cancelToken: cancelToken,
          retryAttempt: retryAttempt + 1,
        );
      }

      return _mapDioException<T>(e);
    } catch (e, st) {
      return NetworkResponse.failure(
        exception:
            NetworkException(e.toString(), originalError: e, stackTrace: st),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // DioException → typed NetworkException mapping
  // ---------------------------------------------------------------------------

  NetworkResponse<T> _mapDioException<T>(dio.DioException e) {
    final resp = e.response;
    final responseHeaders =
        resp?.headers.map.map((k, v) => MapEntry(k, v.join(', ')));

    switch (e.type) {
      case dio.DioExceptionType.connectionTimeout:
      case dio.DioExceptionType.sendTimeout:
      case dio.DioExceptionType.receiveTimeout:
        return NetworkResponse.failure(
          exception: NetworkTimeoutException('Request timed out',
              originalError: e),
          responseHeaders: responseHeaders,
        );

      case dio.DioExceptionType.connectionError:
        return NetworkResponse.failure(
          exception: NoConnectionException('No internet connection',
              originalError: e),
        );

      case dio.DioExceptionType.badCertificate:
        return NetworkResponse.failure(
          exception:
              SslException('SSL certificate error', originalError: e),
        );

      case dio.DioExceptionType.cancel:
        return NetworkResponse.failure(
          exception: RequestCancelledException('Request cancelled',
              originalError: e),
        );

      case dio.DioExceptionType.badResponse:
        if (resp != null) {
          // Use ResponseParser for consistent error handling
          return _parser.parse<T>(
            statusCode: resp.statusCode ?? 0,
            body: resp.data,
            responseHeaders: responseHeaders,
            reasonPhrase: resp.statusMessage,
          );
        }
        return NetworkResponse.failure(
          statusCode: resp?.statusCode,
          message: e.message,
          exception: NetworkException(e.message ?? 'Bad response',
              statusCode: resp?.statusCode, originalError: e),
          responseHeaders: responseHeaders,
        );

      case dio.DioExceptionType.unknown:
        return NetworkResponse.failure(
          message: e.message,
          exception: NetworkException(e.message ?? 'Unknown error',
              originalError: e),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  dio.ResponseType _mapResponseType(ResponseType type) {
    return switch (type) {
      ResponseType.json => dio.ResponseType.json,
      ResponseType.plain => dio.ResponseType.plain,
      ResponseType.bytes => dio.ResponseType.bytes,
    };
  }

  Map<String, String> _extractHeaders(dio.Response response) {
    return response.headers.map
        .map((key, values) => MapEntry(key, values.join(', ')));
  }

  void _throwIfDisposed() {
    if (_disposed) {
      throw StateError(
          'DioNetworkCaller has been disposed and cannot be used.');
    }
  }
}
