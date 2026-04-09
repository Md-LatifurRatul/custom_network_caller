<p align="center">
  <h1 align="center">network_caller_dio</h1>
  <p align="center">
    Production-ready HTTP networking for Flutter. Zero boilerplate.<br>
    Built on <code>package:dio</code> — with native interceptors and advanced features.
  </p>
</p>

<p align="center">
  <a href="https://pub.dev/packages/network_caller_dio"><img src="https://img.shields.io/pub/v/network_caller_dio.svg" alt="pub package"></a>
  <a href="https://github.com/Md-LatifurRatul/custom_network_caller"><img src="https://img.shields.io/github/license/Md-LatifurRatul/custom_network_caller" alt="License"></a>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-blue" alt="Platform">
</p>

---

## Features

| Feature | Description |
|---------|-------------|
| **Generic Responses** | `NetworkResponse<T>` — parse to any model with a one-line parser |
| **Token Management** | Auto-refresh on 401, concurrent-safe Completer lock, secure storage |
| **4 Auth Strategies** | Bearer, API Key, Basic Auth, Custom — swap with one line |
| **Typed Exceptions** | 10 exception types — pattern-match instead of string checking |
| **Retry with Backoff** | Configurable retry policy, exponential backoff, `Retry-After` support |
| **Request Cancellation** | `DioCancelToken` — cancel any in-flight request |
| **Native Interceptors** | Add your own Dio `Interceptor`s via `extraInterceptors` |
| **Token Interceptor** | Built-in 401 handler with separate Dio instance (no infinite loops) |
| **Logging Interceptor** | Auto-logs requests/responses when `logger` is set |
| **Per-Request Timeout** | Override global timeout on any individual call |
| **Query Parameters** | First-class `queryParameters` map on GET (and all methods) |
| **Response Headers** | Access pagination cursors, ETag, rate-limit info on every response |
| **ResponseType** | JSON (default), plain text, or raw bytes |
| **Multipart Upload** | File upload with `onSendProgress` callback |
| **Resource Cleanup** | `dispose()` to close the Dio instance |

## Installation

```yaml
dependencies:
  network_caller_dio: ^1.0.0
```

> This automatically pulls in `network_caller_core`. You only need **one import**.

## Quick Start

```dart
import 'package:network_caller_dio/network_caller_dio.dart';

// 1. Create caller (once, at app startup)
final caller = DioNetworkCaller(
  config: const NetworkConfig(baseUrl: 'https://api.example.com'),
  tokenStorage: SecureTokenStorage(),
);

// 2. Make requests
final res = await caller.get<User>(
  url: '/profile',
  withToken: true,
  parser: (json) => User.fromJson(json),
);

if (res.isSuccess) {
  print(res.data!.name);
} else {
  print(res.exception); // typed NetworkException
}
```

## Usage Examples

### GET with Query Parameters

```dart
final res = await caller.get<List<Post>>(
  url: '/posts',
  queryParameters: {'userId': '1', 'page': '2'},
  parser: (json) => (json as List).map((e) => Post.fromJson(e)).toList(),
);
```

### POST with Body

```dart
final res = await caller.post<Post>(
  url: '/posts',
  body: {'title': 'New Post', 'body': 'Content here', 'userId': 1},
  withToken: true,
  parser: (json) => Post.fromJson(json),
);
```

### Token Management

```dart
// After login — save tokens
await caller.tokenManager.saveTokens(
  accessToken: loginResponse.accessToken,
  refreshToken: loginResponse.refreshToken,
);

// On logout — clear tokens
await caller.tokenManager.clearTokens();

// 401 auto-refresh happens automatically via TokenInterceptor
```

### Error Handling

```dart
final res = await caller.get(url: '/data');

if (!res.isSuccess) {
  switch (res.exception) {
    case NoConnectionException():
      showSnackbar('No internet connection');
    case NetworkTimeoutException():
      showSnackbar('Request timed out');
    case UnauthorizedException():
      navigateToLogin();
    case SslException():
      showSnackbar('SSL certificate error');
    case RateLimitException(:final retryAfter):
      showSnackbar('Too many requests. Retry in $retryAfter');
    case ServerException(:final statusCode):
      showSnackbar('Server error ($statusCode)');
    default:
      showSnackbar(res.message ?? 'Something went wrong');
  }
}
```

### Custom Dio Interceptors

```dart
final caller = DioNetworkCaller(
  config: const NetworkConfig(baseUrl: 'https://api.example.com'),
  tokenStorage: SecureTokenStorage(),
  extraInterceptors: [
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['X-Request-Id'] = generateUuid();
        handler.next(options);
      },
    ),
  ],
);

// Access underlying Dio for advanced usage
caller.dioInstance.interceptors.add(myCustomInterceptor);
```

### Cancel a Request

```dart
final cancelToken = DioCancelToken();

final future = caller.get(url: '/search?q=flutter', cancelToken: cancelToken);

cancelToken.cancel('User left the page');

final res = await future;
// res.exception is RequestCancelledException
```

### Retry Policy

```dart
final caller = DioNetworkCaller(
  config: const NetworkConfig(
    baseUrl: 'https://api.example.com',
    retryPolicy: RetryPolicy.standard(), // 3 retries, exponential backoff
  ),
  tokenStorage: SecureTokenStorage(),
);
```

### Auth Strategies

```dart
// API Key in query parameter
final caller = DioNetworkCaller(
  config: const NetworkConfig(
    baseUrl: 'https://api.example.com',
    authStrategy: ApiKeyAuthStrategy(
      key: 'your-api-key',
      paramName: 'api_key',
      location: ApiKeyLocation.queryParam,
    ),
  ),
  tokenStorage: SecureTokenStorage(),
);
```

### File Upload with Progress

```dart
final res = await caller.upload<UploadResult>(
  url: '/upload',
  files: [
    NetworkMultipartFile(
      field: 'file',
      bytes: fileBytes,
      filename: 'document.pdf',
      contentType: 'application/pdf',
    ),
  ],
  fields: {'folder': 'documents'},
  withToken: true,
  onProgress: (sent, total) {
    final percent = (sent / total * 100).toStringAsFixed(1);
    print('Upload: $percent%');
  },
  parser: (json) => UploadResult.fromJson(json),
);
```

## Choosing HTTP vs Dio

| | `network_caller_http` | `network_caller_dio` |
|---|---|---|
| Underlying library | `package:http` | `package:dio` |
| Package size | Lighter | Slightly heavier |
| Interceptors | `NetworkMiddleware` | Native Dio `Interceptor` |
| Best for | Simple apps, minimal deps | Advanced apps, complex interceptor chains |
| API | Identical | Identical |

Both packages implement the same `NetworkInterface` — switching is a one-line change.

## Platform Support

| Android | iOS | Web | macOS | Windows | Linux |
|:-------:|:---:|:---:|:-----:|:-------:|:-----:|
|    ✅    |  ✅  |  ✅  |   ✅   |    ✅    |   ✅   |

## License

MIT License. See [LICENSE](LICENSE) for details.
