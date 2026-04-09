import 'package:http/http.dart' as http;
import 'package:network_caller_core/network_caller_core.dart';

/// [CancelToken] implementation for the `http` package.
///
/// Creates a dedicated [http.Client] that can be closed to abort the request.
///
/// ```dart
/// final token = HttpCancelToken();
/// caller.get(url: '/search?q=flutter', cancelToken: token);
/// // Later:
/// token.cancel('User navigated away');
/// ```
class HttpCancelToken implements CancelToken {
  final http.Client _client = http.Client();
  bool _isCancelled = false;
  String? _reason;

  /// The underlying [http.Client] used for the request.
  /// The HTTP caller uses this client instead of its shared client.
  http.Client get client => _client;

  /// The reason for cancellation, if any.
  String? get reason => _reason;

  @override
  void cancel([String? reason]) {
    if (_isCancelled) return;
    _isCancelled = true;
    _reason = reason;
    _client.close();
  }

  @override
  bool get isCancelled => _isCancelled;
}
