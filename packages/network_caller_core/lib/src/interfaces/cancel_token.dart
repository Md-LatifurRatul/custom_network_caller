/// Opaque cancel token for aborting in-flight requests.
///
/// Each implementation wraps its own cancellation mechanism:
/// - HTTP: closes the `http.Client`
/// - Dio: wraps `dio.CancelToken`
///
/// ```dart
/// final token = caller.createCancelToken(); // implementation-specific
/// caller.get(url: '/search?q=flutter', cancelToken: token);
/// // Later:
/// token.cancel('User navigated away');
/// ```
abstract class CancelToken {
  /// Cancels the request. Optionally provide a [reason].
  void cancel([String? reason]);

  /// Whether this token has been cancelled.
  bool get isCancelled;
}
