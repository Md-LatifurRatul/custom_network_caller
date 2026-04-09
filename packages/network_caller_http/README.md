<p align="center">
  <h1 align="center">network_caller_http</h1>
  <p align="center">
    Production-ready HTTP networking for Flutter. Zero boilerplate.<br>
    Built on <code>package:http</code> — just configure once and call.
  </p>
</p>

<p align="center">
  <a href="https://pub.dev/packages/network_caller_http"><img src="https://img.shields.io/pub/v/network_caller_http.svg" alt="pub package"></a>
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
| **Request Cancellation** | `HttpCancelToken` — cancel any in-flight request |
| **Per-Request Timeout** | Override global timeout on any individual call |
| **Query Parameters** | First-class `queryParameters` map on GET (and all methods) |
| **Response Headers** | Access pagination cursors, ETag, rate-limit info on every response |
| **ResponseType** | JSON (default), plain text, or raw bytes |
| **Multipart Upload** | File upload with progress callback |
| **Middleware** | `NetworkMiddleware` — hook into request/response/error pipeline |
| **Logging** | `ConsoleNetworkLogger` or implement your own |
| **Form-Encoded** | Auto-detected by Content-Type header |
| **Resource Cleanup** | `dispose()` to close the HTTP client |

## Installation

```yaml
dependencies:
  network_caller_http: ^1.0.0
```

> This automatically pulls in `network_caller_core`. You only need **one import**.

## Quick Start

```dart
import 'package:network_caller_http/network_caller_http.dart';

// 1. Create caller (once, at app startup)
final caller = HttpNetworkCaller(
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

// 401 auto-refresh happens automatically when withToken: true
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
    case RateLimitException(:final retryAfter):
      showSnackbar('Too many requests. Retry in $retryAfter');
    case ServerException(:final statusCode):
      showSnackbar('Server error ($statusCode)');
    case ClientException(:final statusCode):
      showSnackbar('Error ($statusCode): ${res.message}');
    default:
      showSnackbar(res.message ?? 'Something went wrong');
  }
}
```

### Cancel a Request

```dart
final cancelToken = HttpCancelToken();

// Start request
final future = caller.get(url: '/search?q=flutter', cancelToken: cancelToken);

// Cancel it (e.g., user navigated away)
cancelToken.cancel('User left the page');

final res = await future;
// res.exception is RequestCancelledException
```

### Per-Request Timeout

```dart
final res = await caller.get(
  url: '/slow-endpoint',
  timeout: const Duration(seconds: 60), // override global 15s
);
```

### Retry Policy

```dart
final caller = HttpNetworkCaller(
  config: const NetworkConfig(
    baseUrl: 'https://api.example.com',
    retryPolicy: RetryPolicy.standard(), // 3 retries, exponential backoff
  ),
  tokenStorage: SecureTokenStorage(),
);

// Custom retry
final caller2 = HttpNetworkCaller(
  config: NetworkConfig(
    baseUrl: 'https://api.example.com',
    retryPolicy: RetryPolicy(
      maxRetries: 5,
      initialDelay: Duration(seconds: 1),
      backoffMultiplier: 2.0,
      retryWhen: (code) => code >= 500, // only server errors
    ),
  ),
  tokenStorage: SecureTokenStorage(),
);
```

### Auth Strategies

```dart
// API Key in header
final caller = HttpNetworkCaller(
  config: const NetworkConfig(
    baseUrl: 'https://api.example.com',
    authStrategy: ApiKeyAuthStrategy(
      key: 'your-api-key',
      paramName: 'x-api-key',
      location: ApiKeyLocation.header,
    ),
  ),
  tokenStorage: SecureTokenStorage(),
);

// Basic Auth
final caller2 = HttpNetworkCaller(
  config: const NetworkConfig(
    baseUrl: 'https://api.example.com',
    authStrategy: BasicAuthStrategy(username: 'admin', password: 'secret'),
  ),
  tokenStorage: SecureTokenStorage(),
);
```

### Middleware

```dart
final caller = HttpNetworkCaller(
  config: NetworkConfig(
    baseUrl: 'https://api.example.com',
    middlewares: [
      NetworkMiddleware(
        onRequest: (ctx) async {
          ctx.headers['X-Tenant-Id'] = '12345';
        },
        onResponse: (statusCode, body) async {
          print('Response: $statusCode');
        },
      ),
    ],
  ),
  tokenStorage: SecureTokenStorage(),
);
```

### Wrapped API Responses

```dart
// Your API returns: {"data": {...}, "meta": {"page": 1}}
final caller = HttpNetworkCaller(
  config: NetworkConfig(
    baseUrl: 'https://api.example.com',
    responseUnwrapper: (body) => body['data'], // extracts 'data' before parser
  ),
  tokenStorage: SecureTokenStorage(),
);
```

### File Upload

```dart
final res = await caller.upload<UploadResult>(
  url: '/upload',
  files: [
    NetworkMultipartFile(
      field: 'avatar',
      bytes: imageBytes,
      filename: 'photo.jpg',
      contentType: 'image/jpeg',
    ),
  ],
  fields: {'description': 'Profile photo'},
  withToken: true,
  onProgress: (sent, total) => print('${sent / total * 100}%'),
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
