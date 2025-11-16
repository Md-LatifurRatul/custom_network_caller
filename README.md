```markdown
# 📡 Flutter Network Caller (HTTP + Dio)

A clean, extensible, production-ready networking layer for Flutter projects.  
This package provides **two fully independent network callers**:

- **`HttpNetworkCaller`** – lightweight, built on `http`
- **`DioNetworkCaller`** – powerful, with interceptors & retries

> You decide which one to use — **no factory, no enums.**

---

## 📁 Folder Structure
```plaintext
lib/
  services/
    network/
      network_interface.dart
      network_config.dart
      token_manager.dart
      http_network_caller.dart
      dio_network_caller.dart
      token_interceptor_dio.dart
```

---

## 🚀 Features

### 🔐 Token System (Optional)
- Save access token
- Save refresh token
- Auto-add token when `withToken: true`
- Auto-refresh expired token
- Auto-logout callback
- Secure storage

### 🌐 Networking
- `GET` / `POST` / `PUT` / `PATCH` / `DELETE`
- JSON body & response
- Custom headers
- Timeout handling
- Built-in error formatting
- Automatic parsing with custom parser

---

## ⚙️ 1. Setup

### 1.1 Add dependencies
```yaml
dependencies:
  http: 
  dio:
  flutter_secure_storage: 
```

### ⛽ 1.2 `network_config.dart`
```dart
class NetworkConfig {
  static const baseUrl = 'https://api.some-example.com';

  static const defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const timeout = Duration(seconds: 15);
}
```

### 🔑 1.3 Token Manager
> Manages access & refresh tokens.

```dart
class TokenManager {
  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';

  static Future<void> saveAccessToken(String token) async {}
  static Future<void> saveRefreshToken(String token) async {}

  static Future<String?> getAccessToken() async {}
  static Future<String?> getRefreshToken() async {}

  static Future<void> clearTokens() async {}
}
```

---

## 🔌 2. Usage Examples

---

### 🟦 HTTP Caller (Simple & Lightweight)

#### Import
```dart
final httpCaller = HttpNetworkCaller();
```

#### 📥 GET Request
```dart
final res = await httpCaller.getRequest(
  url: '/profile',
  withToken: true,
);

if (res.success) {
  print(res.data);
} else {
  print(res.message);
}
```

#### 📤 POST Request
```dart
final res = await httpCaller.postRequest(
  url: '/login',
  body: {
    'email': 'demo@mail.com',
    'password': '123456',
  },
  parser: (json) => User.fromJson(json),
);

if (res.success) {
  final user = res.data;
}
```

#### 🚫 Logout (token clear)
```dart
await TokenManager.clearTokens();
```

---

### 🔶 DIO Caller (Advanced & Powerful)

#### Import
```dart
final dioCaller = DioNetworkCaller();
```

#### 📥 GET Request
```dart
final res = await dioCaller.getRequest(
  url: '/dashboard',
  withToken: true,
);

if (res.success) {
  print(res.data);
}
```

#### 📤 POST Request
```dart
final res = await dioCaller.postRequest(
  url: '/post',
  body: {
    'title': 'Hello World',
    'description': 'This is new',
  },
);
```

#### 🔄 Automatic Token Refresh
> When API returns `401`, Dio interceptor automatically:
> - Uses the refresh token
> - Requests a new access token
> - Saves it
> - Retries the original request

> **You don’t do anything manually.**

#### 🧹 Auto Logout on Refresh Failure
```dart
dioCaller.onLogout = () {
  // Navigate to login page
};
```

---

## 🧪 3. Parsing Example

### Model
```dart
class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'], name: json['name']);
  }
}
```

### Usage
```dart
final response = await httpCaller.getRequest(
  url: '/user',
  parser: (json) => User.fromJson(json),
);

final user = response.data;
```

---

## 🛠 4. Error Handling

### Response wrapper structure:
```dart
class NetworkResponse<T> {
  bool success;
  T? data;
  String? message;
  int? statusCode;

  NetworkResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });
}
```

---

## 🧵 5. Common Examples

### Custom Header
```dart
await dioCaller.getRequest(
  url: '/test',
  headers: {'x-id': '123'},
);
```

### Disable Token Authentication
```dart
await httpCaller.getRequest(
  url: '/public-api',
  withToken: false,
);
```

### Upload Image (Dio Recommended)
```dart
await dioCaller.postRequest(
  url: '/upload',
  body: FormData.fromMap({
    'photo': await MultipartFile.fromFile(path),
  }),
);
```

---

## 🧩 6. Best Practices

| Prefer **Dio** for: | Prefer **HTTP** for: |
|---------------------|------------------------|
| ✔ interceptors, refresh, retries | ✔ simple requests |
| ✔ uploads/downloads | ✔ small apps |
| ✔ large production apps | ✔ lower dependency count |

> - Keep `NetworkInterface` stable  
> - Model parsing in separate files  
> - Avoid logic in UI  
> - Auto-refresh only inside Dio caller

---

## 🧰 7. Example Project Structure
```plaintext
lib/
  models/
    user.dart
  services/
    network/
      network_interface.dart
      http_network_caller.dart
      dio_network_caller.dart
      token_manager.dart
    repositories/
      auth_repository.dart
  pages/
    login_page.dart
    home_page.dart
```

---
