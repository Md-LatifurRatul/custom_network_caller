import 'dart:convert';

import 'package:network_caller_core/network_caller_core.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryTokenStorage storage;
  late TokenManager tokenManager;

  setUp(() {
    storage = InMemoryTokenStorage();
    tokenManager = TokenManager(storage);
  });

  group('BearerAuthStrategy', () {
    const strategy = BearerAuthStrategy();

    test('adds Bearer token when available', () async {
      await tokenManager.saveTokens(accessToken: 'tok123');
      final headers = await strategy.buildAuthHeaders(tokenManager);
      expect(headers['Authorization'], 'Bearer tok123');
    });

    test('returns empty when no token', () async {
      final headers = await strategy.buildAuthHeaders(tokenManager);
      expect(headers, isEmpty);
    });

    test('returns empty query params', () async {
      final params = await strategy.buildAuthQueryParams(tokenManager);
      expect(params, isEmpty);
    });
  });

  group('ApiKeyAuthStrategy', () {
    test('header location adds to headers', () async {
      const strategy = ApiKeyAuthStrategy(
        key: 'my-key',
        location: ApiKeyLocation.header,
        paramName: 'x-api-key',
      );
      final headers = await strategy.buildAuthHeaders(tokenManager);
      expect(headers['x-api-key'], 'my-key');

      final params = await strategy.buildAuthQueryParams(tokenManager);
      expect(params, isEmpty);
    });

    test('queryParam location adds to query', () async {
      const strategy = ApiKeyAuthStrategy(
        key: 'my-key',
        location: ApiKeyLocation.queryParam,
        paramName: 'api_key',
      );
      final headers = await strategy.buildAuthHeaders(tokenManager);
      expect(headers, isEmpty);

      final params = await strategy.buildAuthQueryParams(tokenManager);
      expect(params['api_key'], 'my-key');
    });
  });

  group('BasicAuthStrategy', () {
    test('adds Basic auth header', () async {
      const strategy = BasicAuthStrategy(username: 'admin', password: 'secret');
      final headers = await strategy.buildAuthHeaders(tokenManager);
      final expected = base64Encode(utf8.encode('admin:secret'));
      expect(headers['Authorization'], 'Basic $expected');
    });
  });

  group('CustomAuthStrategy', () {
    test('calls headerBuilder function', () async {
      await tokenManager.saveTokens(accessToken: 'custom-tok');
      final strategy = CustomAuthStrategy(
        headerBuilder: (tm) async {
          final token = await tm.getAccessToken();
          return {'X-Custom': token ?? '', 'X-Tenant': 'tenant-1'};
        },
      );

      final headers = await strategy.buildAuthHeaders(tokenManager);
      expect(headers['X-Custom'], 'custom-tok');
      expect(headers['X-Tenant'], 'tenant-1');
    });
  });
}
