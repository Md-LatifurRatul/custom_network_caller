<p align="center">
  <h1 align="center">Network Caller</h1>
  <p align="center">
    <strong>Production-ready networking for Flutter. Zero boilerplate.</strong><br>
    Choose <code>http</code> or <code>dio</code> — everything else is handled for you.
  </p>
</p>

<p align="center">
  <a href="https://pub.dev/packages/network_caller_http"><img src="https://img.shields.io/pub/v/network_caller_http.svg?label=network_caller_http" alt="HTTP package"></a>
  <a href="https://pub.dev/packages/network_caller_dio"><img src="https://img.shields.io/pub/v/network_caller_dio.svg?label=network_caller_dio" alt="Dio package"></a>
  <a href="https://github.com/Md-LatifurRatul/custom_network_caller"><img src="https://img.shields.io/github/license/Md-LatifurRatul/custom_network_caller" alt="License"></a>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-blue" alt="Platform">
</p>

---

## Why Network Caller?

| Problem | Network Caller Solution |
|---------|------------------------|
| Writing the same networking boilerplate in every project | Configure once, use everywhere |
| Token management scattered across files | Built-in secure token storage with auto-refresh |
| No typed errors — checking string messages | 10 typed exceptions with pattern matching |
| Pulling in `dio` when you only need `http` | Choose one — zero unnecessary dependencies |
| Different error handling per project | Consistent `NetworkResponse<T>` across all calls |
| Manual retry logic | Configurable exponential backoff with `Retry-After` |

## Packages

This is a **federated monorepo** — pick the one you need:

| Package | Description | Pub |
|---------|-------------|-----|
| [`network_caller_http`](packages/network_caller_http/) | Implementation using `package:http` | [![pub](https://img.shields.io/pub/v/network_caller_http.svg)](https://pub.dev/packages/network_caller_http) |
| [`network_caller_dio`](packages/network_caller_dio/) | Implementation using `package:dio` | [![pub](https://img.shields.io/pub/v/network_caller_dio.svg)](https://pub.dev/packages/network_caller_dio) |
| [`network_caller_core`](packages/network_caller_core/) | Shared interfaces and models (auto-included) | [![pub](https://img.shields.io/pub/v/network_caller_core.svg)](https://pub.dev/packages/network_caller_core) |

## Quick Start

### 1. Install

```yaml
# Pick ONE:
dependencies:
  network_caller_http: ^1.0.0   # uses package:http
  # OR
  network_caller_dio: ^1.0.0    # uses package:dio
```

### 2. Configure (once)

```dart
import 'package:network_caller_http/network_caller_http.dart';
// OR: import 'package:network_caller_dio/network_caller_dio.dart';

final caller = HttpNetworkCaller(  // or DioNetworkCaller
  config: const NetworkConfig(baseUrl: 'https://api.example.com'),
  tokenStorage: SecureTokenStorage(),
);
```

### 3. Use

```dart
// GET with model parsing
final res = await caller.get<User>(
  url: '/profile',
  withToken: true,
  parser: (json) => User.fromJson(json),
);

if (res.isSuccess) {
  final user = res.data!;
}
```

That's it. Tokens, refresh, errors, retry — all handled internally.

## Feature Overview

| Feature | Status |
|---------|--------|
| GET / POST / PUT / PATCH / DELETE | Built-in |
| Generic `<T>` response parsing | Built-in |
| Bearer / API Key / Basic / Custom Auth | Built-in |
| Auto token refresh on 401 | Built-in |
| Concurrent refresh lock (Completer) | Built-in |
| Typed exceptions (10 types) | Built-in |
| Retry with exponential backoff | Configurable |
| `Retry-After` header support (429) | Automatic |
| Request cancellation | Built-in |
| Per-request timeout override | Built-in |
| Query parameters | Built-in |
| Response headers access | Built-in |
| Multipart file upload with progress | Built-in |
| Request/response logging | Configurable |
| Middleware (HTTP) / Interceptors (Dio) | Built-in |
| ResponseType (JSON / plain / bytes) | Built-in |
| Form URL-encoded body | Auto-detected |
| Wrapped API unwrapping | Configurable |
| Custom error parsing | Configurable |
| Custom success status codes | Configurable |
| Secure token storage | Built-in |
| Resource cleanup (dispose) | Built-in |

## Platform Support

| Android | iOS | Web | macOS | Windows | Linux |
|:-------:|:---:|:---:|:-----:|:-------:|:-----:|
|    ✅    |  ✅  |  ✅  |   ✅   |    ✅    |   ✅   |

## Architecture

```
network_caller_core        ← Pure Dart, zero dependencies
       ↑                          ↑
network_caller_http       network_caller_dio
(package:http)            (package:dio)
```

- **Core** defines interfaces, models, config, exceptions
- **HTTP/Dio** implement the `NetworkInterface` contract
- Consumer imports **one** package — core is re-exported automatically

## Documentation

- [HTTP Package README](packages/network_caller_http/README.md) — full API reference with examples
- [Dio Package README](packages/network_caller_dio/README.md) — full API reference with examples
- [Core Package README](packages/network_caller_core/README.md) — interfaces and types reference

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## License

MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with Dart & Flutter<br>
  <a href="https://github.com/Md-LatifurRatul/custom_network_caller">GitHub</a>
</p>
