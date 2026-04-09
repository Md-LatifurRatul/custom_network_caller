import 'dart:convert';

import 'package:network_caller_core/src/token/token_manager.dart';

/// Determines how authentication headers are built for each request.
///
/// The default [BearerAuthStrategy] reads the access token from
/// [TokenManager] and adds `Authorization: Bearer <token>`.
///
/// For other auth schemes, use [ApiKeyAuthStrategy], [BasicAuthStrategy],
/// or [CustomAuthStrategy].
abstract class AuthStrategy {
  const AuthStrategy();

  /// Builds auth headers to merge into the request.
  ///
  /// Returns an empty map if no auth should be applied.
  Future<Map<String, String>> buildAuthHeaders(TokenManager tokenManager);

  /// Builds auth query parameters to append to the URL.
  ///
  /// Returns an empty map for header-based strategies.
  Future<Map<String, String>> buildAuthQueryParams(TokenManager tokenManager) {
    return Future.value(const {});
  }
}

/// Reads the access token from [TokenManager] and adds
/// `Authorization: Bearer <token>`.
///
/// This is the default strategy — no configuration needed.
class BearerAuthStrategy extends AuthStrategy {
  const BearerAuthStrategy();

  @override
  Future<Map<String, String>> buildAuthHeaders(
    TokenManager tokenManager,
  ) async {
    final token = await tokenManager.getAccessToken();
    if (token != null && token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    return const {};
  }
}

/// Where the API key should be placed.
enum ApiKeyLocation { header, queryParam }

/// Adds an API key to requests — either as a header or a query parameter.
///
/// ```dart
/// ApiKeyAuthStrategy(
///   key: 'your-api-key',
///   location: ApiKeyLocation.header,
///   paramName: 'x-api-key',
/// )
/// ```
class ApiKeyAuthStrategy extends AuthStrategy {
  final String key;
  final ApiKeyLocation location;
  final String paramName;

  const ApiKeyAuthStrategy({
    required this.key,
    this.location = ApiKeyLocation.header,
    this.paramName = 'x-api-key',
  });

  @override
  Future<Map<String, String>> buildAuthHeaders(
    TokenManager tokenManager,
  ) async {
    if (location == ApiKeyLocation.header) {
      return {paramName: key};
    }
    return const {};
  }

  @override
  Future<Map<String, String>> buildAuthQueryParams(
    TokenManager tokenManager,
  ) async {
    if (location == ApiKeyLocation.queryParam) {
      return {paramName: key};
    }
    return const {};
  }
}

/// Adds `Authorization: Basic <base64(username:password)>` to requests.
///
/// ```dart
/// BasicAuthStrategy(username: 'admin', password: 'secret')
/// ```
class BasicAuthStrategy extends AuthStrategy {
  final String username;
  final String password;

  const BasicAuthStrategy({required this.username, required this.password});

  @override
  Future<Map<String, String>> buildAuthHeaders(
    TokenManager tokenManager,
  ) async {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    return {'Authorization': 'Basic $credentials'};
  }
}

/// Lets the consumer provide a custom function that builds auth headers.
///
/// Use for session-based auth, multi-header auth, or any non-standard scheme.
///
/// ```dart
/// CustomAuthStrategy(
///   headerBuilder: (tokenManager) async => {
///     'X-Custom-Auth': await tokenManager.getAccessToken() ?? '',
///     'X-Tenant-Id': '12345',
///   },
/// )
/// ```
class CustomAuthStrategy extends AuthStrategy {
  final Future<Map<String, String>> Function(TokenManager tokenManager)
  headerBuilder;

  const CustomAuthStrategy({required this.headerBuilder});

  @override
  Future<Map<String, String>> buildAuthHeaders(
    TokenManager tokenManager,
  ) async {
    return headerBuilder(tokenManager);
  }
}
