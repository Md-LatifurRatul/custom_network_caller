## 1.0.1

- Widened dependency constraints to support latest versions of http and flutter_secure_storage

## 1.0.0

- Initial release
- Full `NetworkInterface` implementation using `package:http`
- `SecureTokenStorage` backed by `flutter_secure_storage` with namespaced keys
- `HttpCancelToken` for request cancellation
- Auto token refresh on 401 with Completer-based concurrent lock
- Retry policy with exponential backoff and `Retry-After` header support
- `NetworkMiddleware` pipeline (onRequest, onResponse, onError)
- Per-request timeout override
- Query parameters support
- ResponseType support (JSON, plain text, raw bytes)
- Form URL-encoded body auto-detection
- Multipart file upload with progress callback
- Request/response logging via `NetworkLogger`
- Error mapping to typed exceptions (SocketException, TimeoutException, HandshakeException, TlsException)
- `dispose()` for resource cleanup
- Supports Android, iOS, Web, macOS, Windows, Linux
