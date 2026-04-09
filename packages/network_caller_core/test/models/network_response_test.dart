import 'package:network_caller_core/network_caller_core.dart';
import 'package:test/test.dart';

void main() {
  group('NetworkResponse', () {
    test('success factory creates correct response', () {
      final res = NetworkResponse<String>.success(
        statusCode: 200,
        message: 'OK',
        data: 'hello',
        responseHeaders: {'content-type': 'text/plain'},
      );

      expect(res.isSuccess, isTrue);
      expect(res.statusCode, 200);
      expect(res.message, 'OK');
      expect(res.data, 'hello');
      expect(res.responseHeaders?['content-type'], 'text/plain');
      expect(res.error, isNull);
      expect(res.exception, isNull);
    });

    test('failure factory creates correct response', () {
      final res = NetworkResponse<String>.failure(
        statusCode: 404,
        message: 'Not Found',
        error: const ErrorResponse(statusCode: 404, message: 'Not Found'),
        exception: const ClientException('Not Found', statusCode: 404),
      );

      expect(res.isSuccess, isFalse);
      expect(res.statusCode, 404);
      expect(res.message, 'Not Found');
      expect(res.data, isNull);
      expect(res.error, isNotNull);
      expect(res.exception, isA<ClientException>());
    });

    test('failure auto-fills statusCode from exception', () {
      final res = NetworkResponse<void>.failure(
        exception: const UnauthorizedException('Session expired'),
      );

      expect(res.statusCode, 401);
      expect(res.message, 'Session expired');
    });

    test('failure auto-fills message from error when no exception', () {
      final res = NetworkResponse<void>.failure(
        error: const ErrorResponse(message: 'Server error'),
      );

      expect(res.message, 'Server error');
    });

    test('const constructor works', () {
      const res = NetworkResponse<String>(isSuccess: true, statusCode: 200);
      expect(res.isSuccess, isTrue);
    });

    test('toString includes key fields', () {
      final res = NetworkResponse<int>.success(statusCode: 200, data: 42);
      expect(res.toString(), contains('isSuccess: true'));
      expect(res.toString(), contains('200'));
    });
  });

  group('ErrorResponse', () {
    test('const constructor works', () {
      const err = ErrorResponse(statusCode: 500, message: 'Internal');
      expect(err.statusCode, 500);
      expect(err.message, 'Internal');
    });

    test('copyWith replaces fields', () {
      const original = ErrorResponse(statusCode: 500, message: 'Old');
      final copy = original.copyWith(message: 'New');
      expect(copy.message, 'New');
      expect(copy.statusCode, 500);
    });
  });
}
