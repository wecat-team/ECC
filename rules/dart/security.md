---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
  - "**/AndroidManifest.xml"
  - "**/Info.plist"
---
# Bảo mật Dart/Flutter

> File này mở rộng [common/security.md](../common/security.md) với nội dung dành riêng cho Dart, Flutter và mobile.

## Quản lý Secret

- KHÔNG BAO GIỜ hardcode API key, token hoặc credential trong source Dart
- Dùng `--dart-define` hoặc `--dart-define-from-file` cho cấu hình compile-time (các giá trị này không thực sự bí mật — hãy dùng backend proxy cho secret phía server)
- Dùng `flutter_dotenv` hoặc tương đương, với các file `.env` được liệt kê trong `.gitignore`
- Lưu secret lúc runtime trong kho lưu trữ an toàn của nền tảng: `flutter_secure_storage` (Keychain trên iOS, EncryptedSharedPreferences trên Android)

```dart
// BAD
const apiKey = 'sk-abc123...';

// GOOD — compile-time config (not secret, just configurable)
const apiKey = String.fromEnvironment('API_KEY');

// GOOD — runtime secret from secure storage
final token = await secureStorage.read(key: 'auth_token');
```

## Bảo mật mạng

- Ép buộc HTTPS — không có lời gọi `http://` trong production
- Cấu hình `network_security_config.xml` của Android để chặn cleartext traffic
- Đặt `NSAppTransportSecurity` trong `Info.plist` để không cho phép arbitrary loads
- Đặt timeout cho request trên mọi HTTP client — không bao giờ để mặc định
- Cân nhắc certificate pinning cho các endpoint yêu cầu bảo mật cao

```dart
// Dio with timeout and HTTPS enforcement
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.example.com',
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
));
```

## Kiểm tra đầu vào (Input Validation)

- Validate và sanitize mọi input của người dùng trước khi gửi tới API hoặc lưu trữ
- KHÔNG BAO GIỜ truyền input chưa sanitize vào truy vấn SQL — dùng truy vấn tham số hóa (sqflite, drift)
- Sanitize URL deep link trước khi điều hướng — validate scheme, host và các tham số path
- Dùng `Uri.tryParse` và validate trước khi điều hướng

```dart
// BAD — SQL injection
await db.rawQuery("SELECT * FROM users WHERE email = '$userInput'");

// GOOD — parameterized
await db.query('users', where: 'email = ?', whereArgs: [userInput]);

// BAD — unvalidated deep link
final uri = Uri.parse(incomingLink);
context.go(uri.path); // could navigate to any route

// GOOD — validated deep link
final uri = Uri.tryParse(incomingLink);
if (uri != null && uri.host == 'myapp.com' && _allowedPaths.contains(uri.path)) {
  context.go(uri.path);
}
```

## Bảo vệ dữ liệu

- Chỉ lưu token, PII và credential trong `flutter_secure_storage`
- KHÔNG BAO GIỜ ghi dữ liệu nhạy cảm vào `SharedPreferences` hoặc file cục bộ dưới dạng plaintext
- Xóa trạng thái xác thực khi logout: token, dữ liệu người dùng được cache, cookie
- Dùng xác thực sinh trắc học (`local_auth`) cho các thao tác nhạy cảm
- Tránh log dữ liệu nhạy cảm — không có `print(token)` hay `debugPrint(password)`

## Riêng cho Android

- Chỉ khai báo các permission cần thiết trong `AndroidManifest.xml`
- Chỉ export các component Android (`Activity`, `Service`, `BroadcastReceiver`) khi cần thiết; thêm `android:exported="false"` ở những chỗ không cần
- Rà soát intent filter — các component được export với implicit intent filter có thể bị bất kỳ ứng dụng nào truy cập
- Dùng `FLAG_SECURE` cho các màn hình hiển thị dữ liệu nhạy cảm (ngăn chụp màn hình)

```xml
<!-- AndroidManifest.xml — restrict exported components -->
<activity android:name=".MainActivity" android:exported="true">
    <!-- Only the launcher activity needs exported=true -->
</activity>
<activity android:name=".SensitiveActivity" android:exported="false" />
```

## Riêng cho iOS

- Chỉ khai báo các usage description cần thiết trong `Info.plist` (`NSCameraUsageDescription`, v.v.)
- Lưu secret trong Keychain — `flutter_secure_storage` dùng Keychain trên iOS
- Dùng App Transport Security (ATS) — không cho phép arbitrary loads
- Bật data protection entitlement cho các file nhạy cảm

## Bảo mật WebView

- Dùng `webview_flutter` v4+ (`WebViewController` / `WebViewWidget`) — widget `WebView` cũ đã bị gỡ bỏ
- Tắt JavaScript trừ khi thực sự cần (`JavaScriptMode.disabled`)
- Validate URL trước khi tải — KHÔNG BAO GIỜ tải URL tùy ý từ deep link
- KHÔNG BAO GIỜ expose Dart callback cho JavaScript trừ khi thực sự cần và đã được sandbox cẩn thận
- Dùng `NavigationDelegate.onNavigationRequest` để chặn và validate các yêu cầu điều hướng

```dart
// webview_flutter v4+ API (WebViewController + WebViewWidget)
final controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.disabled) // disabled unless required
  ..setNavigationDelegate(
    NavigationDelegate(
      onNavigationRequest: (request) {
        final uri = Uri.tryParse(request.url);
        if (uri == null || uri.host != 'trusted.example.com') {
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    ),
  );

// In your widget tree:
WebViewWidget(controller: controller)
```

## Obfuscation và bảo mật Build

- Bật obfuscation trong bản build release: `flutter build apk --obfuscate --split-debug-info=./debug-info/`
- Giữ output của `--split-debug-info` ngoài version control (chỉ dùng để symbolicate crash)
- Đảm bảo rule ProGuard/R8 không vô tình để lộ các class được serialize
- Chạy `flutter analyze` và xử lý mọi cảnh báo trước khi release
