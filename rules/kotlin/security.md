---
paths:
  - "**/*.kt"
  - "**/*.kts"
---
# Bảo mật Kotlin

> File này mở rộng [common/security.md](../common/security.md) với nội dung dành riêng cho Kotlin và Android/KMP.

## Quản lý Secret

- KHÔNG BAO GIỜ hardcode API key, token hoặc credential trong source code
- Dùng `local.properties` (được git-ignore) cho secret phát triển cục bộ
- Dùng các field `BuildConfig` được sinh từ secret của CI cho bản build release
- Dùng `EncryptedSharedPreferences` (Android) hoặc Keychain (iOS) để lưu secret lúc runtime

```kotlin
// BAD
val apiKey = "sk-abc123..."

// GOOD — from BuildConfig (generated at build time)
val apiKey = BuildConfig.API_KEY

// GOOD — from secure storage at runtime
val token = secureStorage.get("auth_token")
```

## Bảo mật mạng

- Chỉ dùng HTTPS — cấu hình `network_security_config.xml` để chặn cleartext
- Pin certificate cho các endpoint nhạy cảm bằng OkHttp `CertificatePinner` hoặc tương đương của Ktor
- Đặt timeout trên mọi HTTP client — không bao giờ để mặc định (có thể là vô hạn)
- Validate và sanitize mọi response từ server trước khi dùng

```xml
<!-- res/xml/network_security_config.xml -->
<network-security-config>
    <base-config cleartextTrafficPermitted="false" />
</network-security-config>
```

## Kiểm tra đầu vào (Input Validation)

- Validate mọi input của người dùng trước khi xử lý hoặc gửi tới API
- Dùng truy vấn tham số hóa cho Room/SQLDelight — KHÔNG BAO GIỜ nối input của người dùng vào SQL
- Sanitize đường dẫn file từ input của người dùng để ngăn path traversal

```kotlin
// BAD — SQL injection
@Query("SELECT * FROM items WHERE name = '$input'")

// GOOD — parameterized
@Query("SELECT * FROM items WHERE name = :input")
fun findByName(input: String): List<ItemEntity>
```

## Bảo vệ dữ liệu

- Dùng `EncryptedSharedPreferences` cho dữ liệu key-value nhạy cảm trên Android
- Dùng `@Serializable` với tên field tường minh — không làm lộ tên property nội bộ
- Xóa dữ liệu nhạy cảm khỏi bộ nhớ khi không còn cần
- Dùng `@Keep` hoặc rule ProGuard cho các class được serialize để tránh bị đổi tên

## Authentication

- Lưu token trong secure storage, không lưu trong SharedPreferences thường
- Triển khai refresh token với xử lý 401/403 đúng cách
- Xóa toàn bộ trạng thái xác thực khi logout (token, dữ liệu người dùng được cache, cookie)
- Dùng xác thực sinh trắc học (`BiometricPrompt`) cho các thao tác nhạy cảm

## ProGuard / R8

- Giữ rule (keep rule) cho mọi model được serialize (`@Serializable`, Gson, Moshi)
- Giữ rule cho các thư viện dựa trên reflection (Koin, Retrofit)
- Test bản build release — obfuscation có thể làm hỏng serialization một cách âm thầm

## Bảo mật WebView

- Tắt JavaScript trừ khi thực sự cần: `settings.javaScriptEnabled = false`
- Validate URL trước khi tải trong WebView
- KHÔNG BAO GIỜ expose các method `@JavascriptInterface` truy cập dữ liệu nhạy cảm
- Dùng `WebViewClient.shouldOverrideUrlLoading()` để kiểm soát điều hướng
