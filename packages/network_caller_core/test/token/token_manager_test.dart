import 'package:network_caller_core/network_caller_core.dart';
import 'package:test/test.dart';

void main() {
  group('TokenManager', () {
    late InMemoryTokenStorage storage;
    late TokenManager manager;

    setUp(() {
      storage = InMemoryTokenStorage();
      manager = TokenManager(storage);
    });

    test('saves and retrieves access token', () async {
      await manager.saveTokens(accessToken: 'abc123');
      expect(await manager.getAccessToken(), 'abc123');
    });

    test('saves and retrieves refresh token', () async {
      await manager.saveTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      expect(await manager.getAccessToken(), 'access');
      expect(await manager.getRefreshToken(), 'refresh');
    });

    test('does not overwrite refresh token when not provided', () async {
      await manager.saveTokens(
          accessToken: 'a1', refreshToken: 'r1');
      await manager.saveTokens(accessToken: 'a2');
      expect(await manager.getAccessToken(), 'a2');
      expect(await manager.getRefreshToken(), 'r1');
    });

    test('clearTokens removes both tokens', () async {
      await manager.saveTokens(
          accessToken: 'a', refreshToken: 'r');
      await manager.clearTokens();
      expect(await manager.getAccessToken(), isNull);
      expect(await manager.getRefreshToken(), isNull);
    });

    test('buildHeaders includes defaults', () async {
      final headers = await manager.buildHeaders(
        baseHeaders: {'Content-Type': 'application/json'},
        authStrategy: const BearerAuthStrategy(),
      );
      expect(headers['Content-Type'], 'application/json');
    });

    test('buildHeaders adds Bearer token when withToken=true', () async {
      await manager.saveTokens(accessToken: 'mytoken');
      final headers = await manager.buildHeaders(
        baseHeaders: {},
        authStrategy: const BearerAuthStrategy(),
        withToken: true,
      );
      expect(headers['Authorization'], 'Bearer mytoken');
    });

    test('buildHeaders does NOT add token when withToken=false', () async {
      await manager.saveTokens(accessToken: 'mytoken');
      final headers = await manager.buildHeaders(
        baseHeaders: {},
        authStrategy: const BearerAuthStrategy(),
        withToken: false,
      );
      expect(headers.containsKey('Authorization'), isFalse);
    });

    test('buildHeaders adds User-Agent when provided', () async {
      final headers = await manager.buildHeaders(
        baseHeaders: {},
        authStrategy: const BearerAuthStrategy(),
        userAgent: 'MyApp/1.0',
      );
      expect(headers['User-Agent'], 'MyApp/1.0');
    });

    test('buildHeaders merges extra headers', () async {
      final headers = await manager.buildHeaders(
        baseHeaders: {'A': '1'},
        authStrategy: const BearerAuthStrategy(),
        extra: {'B': '2'},
      );
      expect(headers['A'], '1');
      expect(headers['B'], '2');
    });

    test('extra headers override defaults', () async {
      final headers = await manager.buildHeaders(
        baseHeaders: {'Content-Type': 'application/json'},
        authStrategy: const BearerAuthStrategy(),
        extra: {'Content-Type': 'text/plain'},
      );
      expect(headers['Content-Type'], 'text/plain');
    });
  });

  group('InMemoryTokenStorage', () {
    test('starts with null tokens', () async {
      final storage = InMemoryTokenStorage();
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });
  });
}
