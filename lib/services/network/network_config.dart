import 'package:network_call/model/token_manager.dart';

class NetworkConfig {
  //The root API domail
  static const baseUrl = "https://api.example.com";
  // Common request headers

  static const defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  static const timeout = Duration(seconds: 15);
  static String? token;

  static Future<Map<String, String>> getHeaders({
    bool withToken = false,
  }) async {
    final headers = {...defaultHeaders};
    if (withToken) {
      final token = await TokenManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }
}
