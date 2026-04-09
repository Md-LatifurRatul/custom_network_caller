import 'dart:async';

import 'package:dio/dio.dart';
import 'package:network_caller_core/network_caller_core.dart';

/// Dio interceptor that handles 401 token refresh and request retry.
///
/// Features:
/// - Completer-based lock prevents concurrent refresh calls
/// - Separate [_refreshDio] instance avoids infinite 401 loop
/// - Custom [TokenExtractor] support for non-standard refresh responses
/// - Clears tokens and triggers [onLogout] on refresh failure
class TokenInterceptor extends Interceptor {
  final Dio dio;
  final TokenManager _tokenManager;
  final NetworkConfig _config;

  /// Separate Dio instance without interceptors — refresh calls go through
  /// this to prevent infinite 401 loops.
  late final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: _config.baseUrl,
      connectTimeout: _config.connectTimeout,
      receiveTimeout: _config.receiveTimeout,
      headers: _config.defaultHeaders,
    ),
  );

  /// Completer acts as a lock: when a refresh is in-flight, subsequent
  /// 401 handlers await this instead of starting another refresh.
  Completer<String?>? _refreshCompleter;

  TokenInterceptor({
    required this.dio,
    required TokenManager tokenManager,
    required NetworkConfig config,
  }) : _tokenManager = tokenManager,
       _config = config;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final resp = err.response;
    if (resp?.statusCode == 401) {
      try {
        final newAccessToken = await _performLockedRefresh();
        if (newAccessToken == null) {
          await _clearAndLogout();
          return handler.next(err);
        }

        // Retry original request with new token
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';

        final clone = Options(
          method: opts.method,
          headers: opts.headers,
          responseType: opts.responseType,
          contentType: opts.contentType,
          followRedirects: opts.followRedirects,
          validateStatus: opts.validateStatus,
          receiveDataWhenStatusError: opts.receiveDataWhenStatusError,
          extra: opts.extra,
        );

        final retryResponse = await dio.request<dynamic>(
          opts.path,
          data: opts.data,
          queryParameters: opts.queryParameters,
          options: clone,
          cancelToken: opts.cancelToken,
          onReceiveProgress: opts.onReceiveProgress,
          onSendProgress: opts.onSendProgress,
        );

        return handler.resolve(retryResponse);
      } catch (e) {
        await _clearAndLogout();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  /// If a refresh is already in-flight, wait for it. Otherwise, start one.
  /// Returns the new access token, or null if refresh failed.
  Future<String?> _performLockedRefresh() async {
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

      final refreshResp = await _refreshDio.post(
        _config.refreshEndpoint,
        data: {'refresh_token': refreshToken},
      );

      if (refreshResp.statusCode != null &&
          refreshResp.statusCode! >= 200 &&
          refreshResp.statusCode! < 300) {
        final data = refreshResp.data as Map<String, dynamic>;

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

  Future<void> _clearAndLogout() async {
    await _tokenManager.clearTokens();
    try {
      await _config.onLogout?.call();
    } catch (_) {}
  }
}
