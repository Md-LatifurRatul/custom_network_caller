import 'package:network_call/core/network/network_interface.dart';
import 'package:network_call/model/network_response.dart';
import 'package:network_call/utils.dart/api_url.dart';

class AuthRepository {
  final NetworkInterface networkCaller;

  AuthRepository({required this.networkCaller});

  Future<NetworkResponse<Map<String, dynamic>>> loginNetwork(
    String username,
    String password,
  ) async {
    final response = await networkCaller.postRequest<Map<String, dynamic>>(
      url: ApiUrl.loginUrl,

      body: {"username": username, "password": password},
    );
    return response;
  }

  Future<NetworkResponse<Map<String, dynamic>>> getUserProfile() async {
    return await networkCaller.getRequest(url: ApiUrl.users, withToken: true);
  }
}
