// ignore_for_file: unused_local_variable

import 'package:network_caller_core/network_caller_core.dart';

/// Demonstrates core package types — config, auth strategies, token manager.
///
/// Note: You don't use this package directly. Use `network_caller_http`
/// or `network_caller_dio` instead. This example shows the shared types.
void main() async {
  // --- NetworkConfig with smart defaults ---
  const config = NetworkConfig(
    baseUrl: 'https://api.example.com',
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 15),
    authStrategy: BearerAuthStrategy(),
    refreshEndpoint: '/auth/refresh',
    retryPolicy: RetryPolicy.standard(),
    logger: ConsoleNetworkLogger(),
  );

  // --- Auth Strategies ---
  const bearer = BearerAuthStrategy();
  const apiKey = ApiKeyAuthStrategy(
    key: 'your-api-key',
    paramName: 'x-api-key',
    location: ApiKeyLocation.header,
  );
  const basic = BasicAuthStrategy(username: 'admin', password: 'secret');

  // --- Token Manager with InMemoryTokenStorage (for testing) ---
  final tokenManager = TokenManager(InMemoryTokenStorage());
  await tokenManager.saveTokens(
    accessToken: 'abc123',
    refreshToken: 'refresh456',
  );

  final token = await tokenManager.getAccessToken();
  print('Access token: $token');

  // --- Build headers with auth ---
  final headers = await tokenManager.buildHeaders(
    baseHeaders: config.defaultHeaders,
    authStrategy: config.authStrategy,
    withToken: true,
  );
  print('Headers: $headers');

  // --- Retry Policy ---
  const retry = RetryPolicy.standard();
  print('Should retry 500 on attempt 0: ${retry.shouldRetry(500, 0)}');
  print('Delay for attempt 2: ${retry.delayForAttempt(2)}');

  // --- NetworkResponse ---
  final success = NetworkResponse<String>.success(
    statusCode: 200,
    data: 'Hello, World!',
  );
  print('Success: ${success.isSuccess}, data: ${success.data}');

  final failure = NetworkResponse<void>.failure(
    exception: const NoConnectionException('No internet'),
  );
  print('Failure: ${failure.exception}');
}
