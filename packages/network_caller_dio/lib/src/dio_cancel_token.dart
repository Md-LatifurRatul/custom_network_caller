import 'package:dio/dio.dart' as dio;
import 'package:network_caller_core/network_caller_core.dart';

/// [CancelToken] implementation wrapping Dio's native [dio.CancelToken].
///
/// ```dart
/// final token = DioCancelToken();
/// caller.get(url: '/search?q=flutter', cancelToken: token);
/// // Later:
/// token.cancel('User navigated away');
/// ```
class DioCancelToken implements CancelToken {
  final dio.CancelToken _token = dio.CancelToken();

  /// The underlying Dio cancel token — used internally by the Dio caller.
  dio.CancelToken get dioToken => _token;

  @override
  void cancel([String? reason]) => _token.cancel(reason);

  @override
  bool get isCancelled => _token.isCancelled;
}
