import 'package:flutter/foundation.dart';
import 'package:network_call/core/network/http_network_caller.dart';
import 'package:network_call/features/auth/auth_repository.dart';
import 'package:network_call/model/token_manager.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository repository = AuthRepository(
    networkCaller: HttpNetworkCaller(),
  );

  bool isLoading = false;
  Map<String, dynamic>? user;

  Future<void> login(String username, String password) async {
    isLoading = true;
    notifyListeners();

    final response = await repository.loginNetwork(username, password);
    isLoading = false;
    print(response.data);
    if (response.isSuccess && response.data != null) {
      await TokenManager.saveTokens(
        accessToken: response.data!['accessToken'],
        refreshToken: response.data!['refreshToken'],
      );
      user = response.data;
      print(user);
    }
    notifyListeners();
  }

  Future<void> loadProfile() async {
    final respnse = await repository.getUserProfile();
    if (respnse.isSuccess) {
      user = respnse.data;
      print("load profile: $user");
      notifyListeners();
    }
  }
}
