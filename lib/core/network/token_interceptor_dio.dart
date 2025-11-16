import 'package:dio/dio.dart';

import '../../model/token_manager.dart';
import 'network_config.dart';

/// Interceptor for Dio: handles refresh & retry on 401.
/// We do not auto-attach token here — callers add `Authorization` via NetworkConfig.getHeaders(withToken:true).
class TokenInterceptorDio extends Interceptor {
  final Dio dio;
  TokenInterceptorDio(this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final resp = err.response;
    if (resp?.statusCode == 401) {
      // Attempt refresh
      final refreshToken = await TokenManager.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await NetworkConfig.clearTokensAndLogout();
        return handler.next(err);
      }

      try {
        // Call refresh endpoint directly ignoring interceptors
        final refreshResp = await dio.post(
          '${NetworkConfig.baseUrl}${NetworkConfig.refreshEndpoint}',
          data: {'refresh_token': refreshToken},
          options: Options(headers: NetworkConfig.defaultHeaders),
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

            // Retry original request with new token
            final opts = err.requestOptions;
            // Update authorization header
            opts.headers['Authorization'] = 'Bearer $newAccess';

            // Create a new request with the same options and fetch
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
          }
        }

        // if refresh failed:
        await NetworkConfig.clearTokensAndLogout();
        return handler.next(err);
      } catch (e) {
        await NetworkConfig.clearTokensAndLogout();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
