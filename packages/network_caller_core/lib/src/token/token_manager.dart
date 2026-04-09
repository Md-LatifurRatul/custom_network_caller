import 'package:network_caller_core/src/auth/auth_strategy.dart';
import 'package:network_caller_core/src/interfaces/token_storage.dart';

/// Instance-based token manager that wraps a [TokenStorage] implementation.
///
/// Unlike the old static `TokenManager`, this is created per-caller instance,
/// making it testable and supporting multiple configurations in the same app.
///
/// Consumers never interact with this directly — it is used internally by
/// the HTTP and Dio callers.
class TokenManager {
  final TokenStorage _storage;

  TokenManager(this._storage);

  /// Save both tokens. [refreshToken] is optional.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.saveAccessToken(accessToken);
    if (refreshToken != null) {
      await _storage.saveRefreshToken(refreshToken);
    }
  }

  Future<String?> getAccessToken() => _storage.getAccessToken();

  Future<String?> getRefreshToken() => _storage.getRefreshToken();

  /// Clears only the token keys — does not wipe other secure storage entries.
  Future<void> clearTokens() => _storage.clearTokens();

  /// Builds the full headers map for a request.
  ///
  /// Merges [baseHeaders] + [userAgent] + auth headers (if [withToken]) + [extra].
  /// Auth headers are built by the [authStrategy].
  Future<Map<String, String>> buildHeaders({
    required Map<String, String> baseHeaders,
    required AuthStrategy authStrategy,
    String? userAgent,
    bool withToken = false,
    Map<String, String>? extra,
  }) async {
    final headers = {...baseHeaders};

    if (userAgent != null) {
      headers['User-Agent'] = userAgent;
    }

    if (withToken) {
      final authHeaders = await authStrategy.buildAuthHeaders(this);
      headers.addAll(authHeaders);
    }

    if (extra != null) {
      headers.addAll(extra);
    }

    return headers;
  }

  /// Builds auth query parameters (for API key in query param, etc.).
  ///
  /// Returns an empty map if [withToken] is false or the strategy
  /// doesn't use query params.
  Future<Map<String, String>> buildAuthQueryParams({
    required AuthStrategy authStrategy,
    bool withToken = false,
  }) async {
    if (!withToken) return const {};
    return authStrategy.buildAuthQueryParams(this);
  }
}
