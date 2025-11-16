import 'package:network_call/utils.dart/api_base_url.dart';

class ApiUrl {
  static const String loginUrl = "${ApiBaseUrl.baseUrl}/auth/login";
  static const String users = "${ApiBaseUrl.baseUrl}/users/1";
  static const String todos = "${ApiBaseUrl.baseUrl}/todos";
  static const String products = "${ApiBaseUrl.baseUrl}/products";
}
