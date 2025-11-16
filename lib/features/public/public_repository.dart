import 'package:network_call/core/network/network_interface.dart';
import 'package:network_call/model/network_response.dart';
import 'package:network_call/utils.dart/api_url.dart';

class PublicRepository {
  final NetworkInterface networkCaller;

  PublicRepository({required this.networkCaller});

  Future<NetworkResponse<List<dynamic>>> getTodos() async {
    return await networkCaller.getRequest(url: ApiUrl.todos);
  }

  Future<NetworkResponse<List<dynamic>>> getProducts() async {
    return await networkCaller.getRequest(url: ApiUrl.products);
  }
}
