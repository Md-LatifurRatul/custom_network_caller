import 'package:network_caller_core/network_caller_core.dart';
import 'package:test/test.dart';

void main() {
  group('NetworkException hierarchy', () {
    test('NetworkTimeoutException', () {
      const e = NetworkTimeoutException('timed out');
      expect(e.message, 'timed out');
      expect(e, isA<NetworkException>());
      expect(e.toString(), contains('NetworkTimeoutException'));
    });

    test('NoConnectionException', () {
      const e = NoConnectionException('no internet');
      expect(e.message, 'no internet');
      expect(e.statusCode, isNull);
    });

    test('UnauthorizedException always has statusCode 401', () {
      const e = UnauthorizedException('expired');
      expect(e.statusCode, 401);
    });

    test('ClientException requires statusCode', () {
      const e = ClientException('not found', statusCode: 404);
      expect(e.statusCode, 404);
    });

    test('ServerException requires statusCode', () {
      const e = ServerException('internal', statusCode: 500);
      expect(e.statusCode, 500);
    });

    test('RateLimitException always has statusCode 429', () {
      const e = RateLimitException(
        'slow down',
        retryAfter: Duration(seconds: 60),
      );
      expect(e.statusCode, 429);
      expect(e.retryAfter, const Duration(seconds: 60));
    });

    test('ParseException preserves rawBody', () {
      const e = ParseException('bad json', rawBody: '{"broken');
      expect(e.rawBody, '{"broken');
    });

    test('RequestCancelledException', () {
      const e = RequestCancelledException('cancelled');
      expect(e.message, 'cancelled');
    });

    test('SslException', () {
      const e = SslException('bad cert');
      expect(e.message, 'bad cert');
    });

    test('all exceptions implement Exception', () {
      const exceptions = <NetworkException>[
        NetworkTimeoutException('t'),
        NoConnectionException('n'),
        UnauthorizedException('u'),
        ClientException('c', statusCode: 400),
        ServerException('s', statusCode: 500),
        RateLimitException('r'),
        ParseException('p'),
        RequestCancelledException('rc'),
        SslException('ssl'),
      ];

      for (final e in exceptions) {
        expect(e, isA<Exception>());
        expect(e, isA<NetworkException>());
      }
      expect(exceptions.length, 9); // all 9 subtypes
    });
  });
}
