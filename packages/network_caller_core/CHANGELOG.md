## 1.0.0

- Initial release
- `NetworkInterface` abstract contract for GET, POST, PUT, PATCH, DELETE, upload, dispose
- `NetworkConfig` with 18+ configurable options and smart defaults
- `NetworkResponse<T>` generic response wrapper with `responseHeaders` and typed `exception`
- `ErrorResponse` model with `copyWith` support
- 10 typed exceptions: `NetworkTimeoutException`, `NoConnectionException`, `UnauthorizedException`, `ClientException`, `ServerException`, `RateLimitException`, `ParseException`, `RequestCancelledException`, `SslException`
- 4 auth strategies: `BearerAuthStrategy`, `ApiKeyAuthStrategy`, `BasicAuthStrategy`, `CustomAuthStrategy`
- `RetryPolicy` with exponential backoff, `Retry-After` header parsing, and configurable predicates
- `TokenStorage` interface with `InMemoryTokenStorage` for testing
- `TokenManager` instance-based token management with header building
- `NetworkLogger` interface with `ConsoleNetworkLogger` default implementation
- `NetworkMiddleware` request/response/error hooks
- `CancelToken` abstract interface
- `ResponseParser` shared parsing logic with unwrapper, message extractor, and error parser support
- `NetworkMultipartFile` platform-agnostic file representation (no `dart:io`)
- `RequestMethod` and `ResponseType` enums
- Pure Dart — zero dependencies, supports all platforms
