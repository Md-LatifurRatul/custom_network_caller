import 'package:dio/dio.dart';
import 'package:network_call/services/network/network_config.dart';
import 'package:network_call/model/token_manager.dart';

class TokenInterceptorDio extends Interceptor {
  final Dio dio;
  TokenInterceptorDio(this.dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenManager.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await TokenManager.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final response = await dio.post(
            '${NetworkConfig.baseUrl}/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          final newAccessToken = response.data['access_token'];
          final newRefreshToken = response.data['refresh_token'];

          await TokenManager.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          final retryRequest = err.requestOptions;
          retryRequest.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await dio.fetch(retryRequest);

          return handler.resolve(retryResponse);
        } catch (_) {
          await TokenManager.clearTokens();
          // TODO: trigger app logout if refresh fails
        }
      } else {
        await TokenManager.clearTokens();
      }
    }

    super.onError(err, handler);
  }
}
