import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:network_caller_core/network_caller_core.dart';

import 'http_cancel_token.dart';

/// Full [NetworkInterface] implementation using the `http` package.
///
/// Handles: auth strategies, token refresh with Completer lock, retry with
/// exponential backoff, per-request timeout, cancellation, middleware pipeline,
/// response headers, responseType (json/plain/bytes), multipart uploads,
/// logging, and typed exceptions.
///
/// ```dart
/// final caller = HttpNetworkCaller(
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
class HttpNetworkCaller implements NetworkInterface {
  final NetworkConfig _config;
  final TokenManager _tokenManager;
  final ResponseParser _parser;
  final http.Client _client;
  bool _disposed = false;

  /// Completer-based lock to prevent concurrent token refreshes.
  Completer<String?>? _refreshCompleter;

  HttpNetworkCaller({
    required NetworkConfig config,
    required TokenStorage tokenStorage,
    http.Client? client,
  }) : _config = config,
       _tokenManager = TokenManager(tokenStorage),
       _parser = ResponseParser(config),
       _client = client ?? http.Client();

  @override
  NetworkConfig get config => _config;

  /// Provides access to [TokenManager] for saving/clearing tokens after login/logout.
  TokenManager get tokenManager => _tokenManager;

  // ---------------------------------------------------------------------------
  // Public API — delegates to _request
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
  }) => _request<T>(
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
  }) => _request<T>(
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
  }) => _request<T>(
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
  }) => _request<T>(
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
  }) => _request<T>(
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
    final stopwatch = Stopwatch()..start();

    try {
      final mergedHeaders = await _tokenManager.buildHeaders(
        baseHeaders: _config.defaultHeaders,
        authStrategy: _config.authStrategy,
        userAgent: _config.userAgent,
        withToken: withToken,
        extra: headers,
      );
      // Remove Content-Type — multipart sets its own boundary
      mergedHeaders.remove('Content-Type');

      final fullUrl = _buildUrl(url, null);
      final request = http.MultipartRequest('POST', fullUrl)
        ..headers.addAll(mergedHeaders);

      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add files
      for (final file in files) {
        request.files.add(
          http.MultipartFile.fromBytes(
            file.field,
            file.bytes,
            filename: file.filename,
          ),
        );
      }

      _config.logger?.logRequest(
        RequestMethod.post,
        fullUrl.toString(),
        headers: mergedHeaders,
        body: '${files.length} file(s), ${fields?.length ?? 0} field(s)',
      );

      final streamedResponse = await request.send().timeout(
        _config.effectiveSendTimeout,
      );

      // Track progress if callback provided
      final totalBytes = streamedResponse.contentLength ?? 0;
      final responseBytes = <int>[];
      int received = 0;

      await for (final chunk in streamedResponse.stream) {
        responseBytes.addAll(chunk);
        received += chunk.length;
        onProgress?.call(received, totalBytes);
      }

      stopwatch.stop();
      final responseBody = utf8.decode(responseBytes);
      final responseHeaders = streamedResponse.headers;

      _config.logger?.logResponse(
        streamedResponse.statusCode,
        fullUrl.toString(),
        body: responseBody,
        elapsed: stopwatch.elapsed,
      );

      final decoded = ResponseParser.decodeJsonBody(responseBody);
      return _parser.parse<T>(
        statusCode: streamedResponse.statusCode,
        body: decoded,
        parser: parser,
        responseHeaders: responseHeaders,
        reasonPhrase: streamedResponse.reasonPhrase,
      );
    } on SocketException catch (e) {
      return NetworkResponse.failure(
        exception: NoConnectionException(
          'No internet connection',
          originalError: e,
        ),
      );
    } on TimeoutException catch (e) {
      return NetworkResponse.failure(
        exception: NetworkTimeoutException(
          'Upload timed out',
          originalError: e,
        ),
      );
    } catch (e, st) {
      if (cancelToken?.isCancelled == true) {
        return NetworkResponse.failure(
          exception: RequestCancelledException(
            'Upload cancelled',
            originalError: e,
          ),
        );
      }
      return NetworkResponse.failure(
        exception: NetworkException(
          e.toString(),
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _client.close();
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
    int refreshRetryCount = 1,
    int retryAttempt = 0,
  }) async {
    _throwIfDisposed();
    final stopwatch = Stopwatch()..start();

    try {
      // Build headers
      final mergedHeaders = await _tokenManager.buildHeaders(
        baseHeaders: _config.defaultHeaders,
        authStrategy: _config.authStrategy,
        userAgent: _config.userAgent,
        withToken: withToken,
        extra: headers,
      );

      // Build URL with query params (including auth query params if applicable)
      final authQueryParams = await _tokenManager.buildAuthQueryParams(
        authStrategy: _config.authStrategy,
        withToken: withToken,
      );
      final allQueryParams = {...?queryParameters, ...authQueryParams};
      final uri = _buildUrl(
        url,
        allQueryParams.isEmpty ? null : allQueryParams,
      );

      // Run middleware onRequest hooks
      final middlewareCtx = MiddlewareRequestContext(
        method: method,
        url: uri.toString(),
        headers: mergedHeaders,
        body: body,
      );
      for (final mw in _config.middlewares) {
        await mw.onRequest?.call(middlewareCtx);
      }

      // Log request
      _config.logger?.logRequest(
        method,
        uri.toString(),
        headers: mergedHeaders,
        body: middlewareCtx.body,
      );

      // Encode body
      final encodedBody = _encodeBody(middlewareCtx.body, mergedHeaders);

      // Select client (cancel token has its own client)
      final activeClient = (cancelToken is HttpCancelToken)
          ? cancelToken.client
          : _client;

      // Execute request
      final effectiveTimeout = timeout ?? _config.connectTimeout;
      final response = await _executeMethod(
        method: method,
        uri: uri,
        headers: middlewareCtx.headers,
        body: encodedBody,
        client: activeClient,
      ).timeout(effectiveTimeout);

      stopwatch.stop();

      // Extract response headers
      final responseHeaders = response.headers;

      // Log response
      _config.logger?.logResponse(
        response.statusCode,
        uri.toString(),
        body: response.body,
        elapsed: stopwatch.elapsed,
      );

      // Run middleware onResponse hooks
      for (final mw in _config.middlewares) {
        await mw.onResponse?.call(response.statusCode, response.body);
      }

      // --- 401 Token Refresh ---
      if (response.statusCode == 401 && withToken && refreshRetryCount > 0) {
        final newToken = await _performLockedRefresh();
        if (newToken != null) {
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
            refreshRetryCount: refreshRetryCount - 1,
            retryAttempt: 0,
          );
        } else {
          await _clearAndLogout();
          return NetworkResponse.failure(
            statusCode: 401,
            message: 'Session expired. Please login again.',
            responseHeaders: responseHeaders,
            exception: const UnauthorizedException(
              'Session expired. Please login again.',
            ),
            error: const ErrorResponse(
              statusCode: 401,
              message: 'Session expired. Please login again.',
            ),
          );
        }
      }

      // --- Retry Policy (5xx, 429, custom) ---
      if (_config.retryPolicy.shouldRetry(response.statusCode, retryAttempt)) {
        // Respect Retry-After header for 429
        Duration delay = _config.retryPolicy.delayForAttempt(retryAttempt);
        if (response.statusCode == 429) {
          final retryAfter = RetryPolicy.parseRetryAfter(
            responseHeaders['retry-after'],
          );
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
          refreshRetryCount: refreshRetryCount,
          retryAttempt: retryAttempt + 1,
        );
      }

      // --- Parse response ---
      final decoded = _decodeResponse(response, responseType);
      return _parser.parse<T>(
        statusCode: response.statusCode,
        body: decoded,
        parser: parser,
        responseHeaders: responseHeaders,
        reasonPhrase: response.reasonPhrase,
      );
    } on SocketException catch (e) {
      _logError(url, e);
      _runMiddlewareOnError(e);
      return NetworkResponse.failure(
        exception: NoConnectionException(
          'No internet connection',
          originalError: e,
        ),
      );
    } on TimeoutException catch (e) {
      _logError(url, e);
      _runMiddlewareOnError(e);
      return NetworkResponse.failure(
        exception: NetworkTimeoutException(
          'Request timed out',
          originalError: e,
        ),
      );
    } on http.ClientException catch (e) {
      _logError(url, e);
      _runMiddlewareOnError(e);
      if (cancelToken?.isCancelled == true) {
        return NetworkResponse.failure(
          exception: RequestCancelledException(
            'Request cancelled',
            originalError: e,
          ),
        );
      }
      return NetworkResponse.failure(
        exception: NetworkException(e.message, originalError: e),
      );
    } on HandshakeException catch (e) {
      _logError(url, e);
      _runMiddlewareOnError(e);
      return NetworkResponse.failure(
        exception: SslException('SSL handshake failed', originalError: e),
      );
    } on TlsException catch (e) {
      _logError(url, e);
      _runMiddlewareOnError(e);
      return NetworkResponse.failure(
        exception: SslException('TLS error: ${e.message}', originalError: e),
      );
    } catch (e, st) {
      _logError(url, e);
      _runMiddlewareOnError(e);
      return NetworkResponse.failure(
        exception: NetworkException(
          e.toString(),
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // HTTP method dispatch
  // ---------------------------------------------------------------------------

  Future<http.Response> _executeMethod({
    required RequestMethod method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
    required http.Client client,
  }) {
    return switch (method) {
      RequestMethod.get => client.get(uri, headers: headers),
      RequestMethod.post => client.post(uri, headers: headers, body: body),
      RequestMethod.put => client.put(uri, headers: headers, body: body),
      RequestMethod.patch => client.patch(uri, headers: headers, body: body),
      RequestMethod.delete => client.delete(uri, headers: headers, body: body),
    };
  }

  // ---------------------------------------------------------------------------
  // URL builder
  // ---------------------------------------------------------------------------

  Uri _buildUrl(String url, Map<String, String>? queryParameters) {
    final fullUrl = url.startsWith('http') ? url : '${_config.baseUrl}$url';
    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(
        queryParameters: {...uri.queryParameters, ...queryParameters},
      );
    }
    return uri;
  }

  // ---------------------------------------------------------------------------
  // Body encoding
  // ---------------------------------------------------------------------------

  String? _encodeBody(dynamic body, Map<String, String> headers) {
    if (body == null) return null;
    if (body is String) return body;

    // Form URL-encoded if Content-Type says so
    final contentType =
        headers['Content-Type'] ?? headers['content-type'] ?? '';
    if (contentType.contains('x-www-form-urlencoded') && body is Map) {
      return body.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key.toString())}=${Uri.encodeComponent(e.value.toString())}',
          )
          .join('&');
    }

    // Default: JSON encode
    return jsonEncode(body);
  }

  // ---------------------------------------------------------------------------
  // Response decoding
  // ---------------------------------------------------------------------------

  dynamic _decodeResponse(http.Response response, ResponseType responseType) {
    switch (responseType) {
      case ResponseType.bytes:
        return response.bodyBytes;
      case ResponseType.plain:
        return response.body;
      case ResponseType.json:
        return ResponseParser.decodeJsonBody(response.body);
    }
  }

  // ---------------------------------------------------------------------------
  // Token refresh with Completer lock
  // ---------------------------------------------------------------------------

  Future<String?> _performLockedRefresh() async {
    // If another request is already refreshing, wait for it
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final refreshUrl = '${_config.baseUrl}${_config.refreshEndpoint}';
      final headers = {..._config.defaultHeaders};
      final resp = await _client
          .post(
            Uri.parse(refreshUrl),
            headers: headers,
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(_config.connectTimeout);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;

        String? newAccess;
        String? newRefresh;

        if (_config.tokenExtractor != null) {
          final extracted = _config.tokenExtractor!(data);
          newAccess = extracted.accessToken;
          newRefresh = extracted.refreshToken;
        } else {
          newAccess = data['access_token'] as String?;
          newRefresh = data['refresh_token'] as String?;
        }

        if (newAccess != null) {
          await _tokenManager.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          _refreshCompleter!.complete(newAccess);
          return newAccess;
        }
      }

      _refreshCompleter!.complete(null);
      return null;
    } catch (e) {
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _clearAndLogout() async {
    await _tokenManager.clearTokens();
    try {
      await _config.onLogout?.call();
    } catch (_) {
      // Swallow logout callback errors
    }
  }

  void _throwIfDisposed() {
    if (_disposed) {
      throw StateError(
        'HttpNetworkCaller has been disposed and cannot be used.',
      );
    }
  }

  void _logError(String url, dynamic error) {
    _config.logger?.logError(url, error: error);
  }

  void _runMiddlewareOnError(dynamic error) {
    for (final mw in _config.middlewares) {
      mw.onError?.call(error);
    }
  }
}
