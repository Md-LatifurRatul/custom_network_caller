import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Save tokens

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  /// Get access token
  static Future<String?> getAccessToken() async =>
      await _storage.read(key: _accessTokenKey);

  /// Get refresh token

  static Future<String?> getRefreshToken() async =>
      await _storage.read(key: _refreshTokenKey);

  /// Clear only token keys (preserves other secure storage entries)
  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
