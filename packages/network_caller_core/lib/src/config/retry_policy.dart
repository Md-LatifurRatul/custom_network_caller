/// Configures automatic retry behavior for failed requests.
///
/// By default, no retries are performed. Use [RetryPolicy.standard] for a
/// sensible preset that retries on 5xx and 429 errors with exponential backoff.
///
/// ```dart
/// // No retries (default)
/// RetryPolicy.none()
///
/// // Retry 3 times on server errors with exponential backoff
/// RetryPolicy.standard()
///
/// // Custom: retry 5 times on specific codes
/// RetryPolicy(
///   maxRetries: 5,
///   retryWhen: (code) => code == 502 || code == 503,
/// )
/// ```
class RetryPolicy {
  /// Maximum number of retry attempts. 0 means no retries.
  final int maxRetries;

  /// Delay before the first retry attempt.
  final Duration initialDelay;

  /// Multiplier applied to the delay for each subsequent attempt.
  ///
  /// With [initialDelay] of 500ms and [backoffMultiplier] of 2.0:
  /// - Attempt 1: 500ms
  /// - Attempt 2: 1000ms
  /// - Attempt 3: 2000ms
  final double backoffMultiplier;

  /// Maximum delay cap — backoff will never exceed this duration.
  final Duration maxDelay;

  /// Predicate that determines which status codes should trigger a retry.
  ///
  /// If null, defaults to retrying on 500, 502, 503, 504, and 429.
  final bool Function(int statusCode)? retryWhen;

  const RetryPolicy({
    this.maxRetries = 0,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.retryWhen,
  });

  /// No retries — default behavior.
  const RetryPolicy.none()
    : maxRetries = 0,
      initialDelay = Duration.zero,
      backoffMultiplier = 1.0,
      maxDelay = Duration.zero,
      retryWhen = null;

  /// Standard preset: retry up to 3 times on server errors (5xx) and 429,
  /// starting at 500ms with 2x exponential backoff, capped at 10s.
  const RetryPolicy.standard()
    : maxRetries = 3,
      initialDelay = const Duration(milliseconds: 500),
      backoffMultiplier = 2.0,
      maxDelay = const Duration(seconds: 10),
      retryWhen = null;

  /// Computes the delay for a given [attempt] (0-indexed).
  ///
  /// Uses exponential backoff: `initialDelay * (backoffMultiplier ^ attempt)`,
  /// capped at [maxDelay].
  Duration delayForAttempt(int attempt) {
    final delayMs =
        initialDelay.inMilliseconds * _pow(backoffMultiplier, attempt);
    final cappedMs = delayMs.clamp(0, maxDelay.inMilliseconds);
    return Duration(milliseconds: cappedMs.toInt());
  }

  /// Returns true if the request should be retried for [statusCode] at [attempt].
  ///
  /// Checks both the attempt count and the status code predicate.
  bool shouldRetry(int statusCode, int attempt) {
    if (attempt >= maxRetries) return false;
    if (retryWhen != null) return retryWhen!(statusCode);
    // Default: retry on server errors and rate limiting
    return statusCode >= 500 || statusCode == 429;
  }

  /// Parses the `Retry-After` header value into a [Duration].
  ///
  /// Supports both formats:
  /// - Seconds: `"120"` → `Duration(seconds: 120)`
  /// - HTTP-date: `"Wed, 09 Apr 2026 12:00:00 GMT"` → computed delta
  ///
  /// Returns null if the header is absent or unparseable.
  static Duration? parseRetryAfter(String? headerValue) {
    if (headerValue == null || headerValue.isEmpty) return null;

    // Try parsing as seconds first
    final seconds = int.tryParse(headerValue);
    if (seconds != null) return Duration(seconds: seconds);

    // Try parsing as HTTP-date
    try {
      final date = DateTime.parse(headerValue);
      final delta = date.difference(DateTime.now());
      return delta.isNegative ? Duration.zero : delta;
    } catch (_) {
      return null;
    }
  }

  static double _pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
