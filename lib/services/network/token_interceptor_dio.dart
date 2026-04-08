import 'dart:async';

import 'package:dio/dio.dart';

import '../../model/token_manager.dart';
import 'network_config.dart';

/// Interceptor for Dio: handles refresh & retry on 401.
/// We do not auto-attach token here — callers add `Authorization` via NetworkConfig.getHeaders(withToken:true).
///
/// Includes a refresh lock so that multiple concurrent 401s don't all
/// trigger separate refresh calls — the first one refreshes, the rest
/// wait and reuse the new token.
class TokenInterceptorDio extends Interceptor {
  final Dio dio;

  /// Separate Dio instance without interceptors — used only for the refresh
  /// call so that a 401 from the refresh endpoint does NOT re-trigger this
  /// interceptor (which would cause an infinite loop).
  late final Dio _refreshDio = Dio(BaseOptions(
    baseUrl: NetworkConfig.baseUrl,
    connectTimeout: NetworkConfig.timeout,
    receiveTimeout: NetworkConfig.timeout,
    headers: NetworkConfig.defaultHeaders,
  ));

  /// Completer acts as a lock: when a refresh is in-flight, subsequent
  /// 401 handlers await this instead of starting another refresh.
  Completer<String?>? _refreshCompleter;

  TokenInterceptorDio(this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final resp = err.response;
    if (resp?.statusCode == 401) {
      try {
        final newAccessToken = await _performLockedRefresh();
        if (newAccessToken == null) {
          await NetworkConfig.clearTokensAndLogout();
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
        await NetworkConfig.clearTokensAndLogout();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  /// If a refresh is already in-flight, wait for it. Otherwise, start one.
  /// Returns the new access token, or null if refresh failed.
  Future<String?> _performLockedRefresh() async {
    // Another call is already refreshing — wait for it
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await TokenManager.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final refreshResp = await _refreshDio.post(
        NetworkConfig.refreshEndpoint,
        data: {'refresh_token': refreshToken},
      );

      if (refreshResp.statusCode != null &&
          refreshResp.statusCode! >= 200 &&
          refreshResp.statusCode! < 300) {
        final newAccess = refreshResp.data['access_token'] as String?;
        final newRefresh = refreshResp.data['refresh_token'] as String?;
        if (newAccess != null) {
          await TokenManager.saveTokens(
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
}
