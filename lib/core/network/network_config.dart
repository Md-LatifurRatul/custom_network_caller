import 'package:flutter/foundation.dart';

import '../../model/token_manager.dart';

typedef LogoutCallback = void Function();

class NetworkConfig {
  // change when building for different environments
  static const String devBaseUrl = 'https://dev.api.example.com';
  static const String prodBaseUrl = 'https://api.example.com';

  // choose environment
  static bool isProduction = false;

  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;

  // Default headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeout duration
  static const Duration timeout = Duration(seconds: 15);

  // Refresh endpoint path (relative to baseUrl) - configurable
  static String refreshEndpoint = '/auth/refresh';

  // App-provided logout callback (set this in main after app startup)
  static LogoutCallback? onLogout;

  /// Helper to get headers. If withToken == true, will attempt to read token.
  /// Always returns a new map.
  static Future<Map<String, String>> getHeaders({
    bool withToken = false,
    Map<String, String>? extra,
  }) async {
    final headers = {...defaultHeaders, ...?extra};
    if (withToken) {
      final token = await TokenManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Clear tokens and trigger logout hook if provided
  static Future<void> clearTokensAndLogout() async {
    await TokenManager.clearTokens();
    try {
      if (onLogout != null) {
        onLogout!();
      }
    } catch (e) {
      if (kDebugMode) {
        print('onLogout callback error: $e');
      }
    }
  }
}
