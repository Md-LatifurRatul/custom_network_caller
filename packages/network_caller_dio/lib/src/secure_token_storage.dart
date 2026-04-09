import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:network_caller_core/network_caller_core.dart';

/// Concrete [TokenStorage] implementation backed by [FlutterSecureStorage].
///
/// Uses platform-specific secure storage:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences / Keystore
/// - Web: WebCrypto + localStorage
///
/// Keys are namespaced with `network_caller_` to avoid collisions.
class SecureTokenStorage implements TokenStorage {
  static const _accessTokenKey = 'network_caller_access_token';
  static const _refreshTokenKey = 'network_caller_refresh_token';

  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  @override
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  @override
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
