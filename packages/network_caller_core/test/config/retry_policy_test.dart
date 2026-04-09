import 'package:network_caller_core/network_caller_core.dart';
import 'package:test/test.dart';

void main() {
  group('RetryPolicy', () {
    test('none() has zero retries', () {
      const policy = RetryPolicy.none();
      expect(policy.maxRetries, 0);
      expect(policy.shouldRetry(500, 0), isFalse);
    });

    test('standard() retries 3 times on 5xx', () {
      const policy = RetryPolicy.standard();
      expect(policy.maxRetries, 3);
      expect(policy.shouldRetry(500, 0), isTrue);
      expect(policy.shouldRetry(502, 1), isTrue);
      expect(policy.shouldRetry(503, 2), isTrue);
      expect(policy.shouldRetry(500, 3), isFalse); // maxRetries reached
    });

    test('standard() retries on 429', () {
      const policy = RetryPolicy.standard();
      expect(policy.shouldRetry(429, 0), isTrue);
    });

    test('standard() does NOT retry on 4xx (except 429)', () {
      const policy = RetryPolicy.standard();
      expect(policy.shouldRetry(400, 0), isFalse);
      expect(policy.shouldRetry(404, 0), isFalse);
      expect(policy.shouldRetry(401, 0), isFalse);
    });

    test('custom retryWhen predicate', () {
      final policy = RetryPolicy(
        maxRetries: 2,
        retryWhen: (code) => code == 503,
      );
      expect(policy.shouldRetry(503, 0), isTrue);
      expect(policy.shouldRetry(500, 0), isFalse);
      expect(policy.shouldRetry(503, 2), isFalse); // max reached
    });

    test('delayForAttempt uses exponential backoff', () {
      const policy = RetryPolicy(
        maxRetries: 5,
        initialDelay: Duration(milliseconds: 100),
        backoffMultiplier: 2.0,
        maxDelay: Duration(seconds: 10),
      );

      expect(policy.delayForAttempt(0), const Duration(milliseconds: 100));
      expect(policy.delayForAttempt(1), const Duration(milliseconds: 200));
      expect(policy.delayForAttempt(2), const Duration(milliseconds: 400));
      expect(policy.delayForAttempt(3), const Duration(milliseconds: 800));
    });

    test('delayForAttempt caps at maxDelay', () {
      const policy = RetryPolicy(
        maxRetries: 10,
        initialDelay: Duration(seconds: 1),
        backoffMultiplier: 10.0,
        maxDelay: Duration(seconds: 5),
      );

      // 1 * 10^3 = 10000ms > 5000ms cap
      expect(policy.delayForAttempt(3), const Duration(seconds: 5));
    });

    test('parseRetryAfter parses seconds', () {
      expect(
        RetryPolicy.parseRetryAfter('120'),
        const Duration(seconds: 120),
      );
    });

    test('parseRetryAfter returns null for garbage', () {
      expect(RetryPolicy.parseRetryAfter('not-a-number'), isNull);
      expect(RetryPolicy.parseRetryAfter(null), isNull);
      expect(RetryPolicy.parseRetryAfter(''), isNull);
    });
  });
}
