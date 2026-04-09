## 1.0.0

- Initial release
- Full `NetworkInterface` implementation using `package:dio`
- `SecureTokenStorage` backed by `flutter_secure_storage` with namespaced keys
- `DioCancelToken` wrapping Dio's native `CancelToken`
- `TokenInterceptor` with Completer-based concurrent refresh lock and separate `_refreshDio` instance
- `LoggingInterceptor` forwarding to `NetworkLogger`
- Support for custom `extraInterceptors` (native Dio `Interceptor`s)
- Retry policy with exponential backoff and `Retry-After` header support
- Per-request timeout override
- Query parameters support
- ResponseType mapping to Dio's native `ResponseType`
- Multipart file upload with `onSendProgress` callback
- DioException mapping to typed exceptions (timeout, connection, SSL, cancel, badResponse)
- `dioInstance` getter for advanced usage
- `dispose()` for resource cleanup
- Supports Android, iOS, Web, macOS, Windows, Linux
