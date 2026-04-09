/// Abstract interface for persisting auth tokens.
///
/// The core package defines this contract — concrete implementations live
/// in the http/dio packages (e.g., `SecureTokenStorage` using
/// `flutter_secure_storage`).
///
/// Consumers can also provide custom implementations (Hive, SharedPreferences,
/// in-memory for tests, etc.).
abstract class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
}

/// In-memory token storage for testing and non-Flutter contexts.
///
/// Tokens are lost when the instance is garbage-collected.
class InMemoryTokenStorage implements TokenStorage {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> saveAccessToken(String token) async {
    _accessToken = token;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    _refreshToken = token;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
