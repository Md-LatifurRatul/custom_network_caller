<p align="center">
  <h1 align="center">network_caller_core</h1>
  <p align="center">
    Core interfaces, models, and configuration for the <strong>network_caller</strong> package federation.
  </p>
</p>

<p align="center">
  <a href="https://pub.dev/packages/network_caller_core"><img src="https://img.shields.io/pub/v/network_caller_core.svg" alt="pub package"></a>
  <a href="https://github.com/Md-LatifurRatul/custom_network_caller"><img src="https://img.shields.io/github/license/Md-LatifurRatul/custom_network_caller" alt="License"></a>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-blue" alt="Platform">
</p>

---

## What is this?

This is the **core** package of the `network_caller` federation. It contains:

- **Interfaces** — `NetworkInterface`, `TokenStorage`, `NetworkLogger`, `CancelToken`
- **Models** — `NetworkResponse<T>`, `ErrorResponse`, `NetworkMultipartFile`
- **Configuration** — `NetworkConfig` with 18+ configurable options
- **Auth Strategies** — `BearerAuthStrategy`, `ApiKeyAuthStrategy`, `BasicAuthStrategy`, `CustomAuthStrategy`
- **Typed Exceptions** — 10 exception types (`NetworkTimeoutException`, `NoConnectionException`, etc.)
- **Retry Policy** — Exponential backoff with `Retry-After` header support
- **Token Manager** — Instance-based, injectable storage

> **You don't use this package directly.** Instead, depend on one of the implementation packages:
>
> - [`network_caller_http`](https://pub.dev/packages/network_caller_http) — uses `package:http`
> - [`network_caller_dio`](https://pub.dev/packages/network_caller_dio) — uses `package:dio`

## Why a Separate Core?

The federated architecture ensures that if you choose the `http` implementation, you **never pull in `dio`** as a dependency (and vice versa). This keeps your app lightweight with zero unnecessary packages.

```
network_caller_core    ← Pure Dart, zero dependencies
       ↑                       ↑
network_caller_http    network_caller_dio
(http + secure_storage) (dio + secure_storage)
```

## Key Types

### NetworkConfig

```dart
const config = NetworkConfig(
  baseUrl: 'https://api.example.com',
  connectTimeout: Duration(seconds: 15),     // default
  receiveTimeout: Duration(seconds: 15),     // default
  authStrategy: BearerAuthStrategy(),        // default
  refreshEndpoint: '/auth/refresh',          // default
  retryPolicy: RetryPolicy.standard(),       // 3 retries, exponential backoff
  logger: ConsoleNetworkLogger(),            // optional
  responseUnwrapper: (body) => body['data'], // for wrapped APIs
  validateStatus: (code) => code < 400,      // custom success check
);
```

### NetworkResponse\<T\>

```dart
final res = await caller.get<User>(url: '/profile', parser: User.fromJson);

if (res.isSuccess) {
  final user = res.data!;
  final headers = res.responseHeaders; // pagination, ETag, etc.
} else {
  // Typed exception for programmatic handling
  switch (res.exception) {
    case NoConnectionException():   print('No internet');
    case NetworkTimeoutException(): print('Timed out');
    case UnauthorizedException():   print('Session expired');
    case RateLimitException(:final retryAfter): print('Wait $retryAfter');
    case ServerException():         print('Server error');
    default: print(res.message);
  }
}
```

### Auth Strategies

```dart
BearerAuthStrategy()                          // Authorization: Bearer <token>
ApiKeyAuthStrategy(key: 'xxx', paramName: 'x-api-key')  // header or queryParam
BasicAuthStrategy(username: 'admin', password: 'secret') // Basic base64
CustomAuthStrategy(headerBuilder: (tm) async => {...})   // any custom scheme
```

## Platform Support

| Android | iOS | Web | macOS | Windows | Linux |
|:-------:|:---:|:---:|:-----:|:-------:|:-----:|
|    ✅    |  ✅  |  ✅  |   ✅   |    ✅    |   ✅   |

This is a **pure Dart** package with zero platform-specific dependencies.

## License

MIT License. See [LICENSE](LICENSE) for details.
