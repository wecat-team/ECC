---
paths:
  - "**/*.swift"
  - "**/Package.swift"
---
# Bảo mật Swift

> File này mở rộng [common/security.md](../common/security.md) với nội dung riêng cho Swift.

## Quản lý secret

- Dùng **Keychain Services** cho dữ liệu nhạy cảm (token, mật khẩu, key) — không bao giờ dùng `UserDefaults`
- Dùng biến môi trường hoặc file `.xcconfig` cho secret lúc build
- Không bao giờ hardcode secret trong source — công cụ decompile trích xuất chúng rất dễ dàng

```swift
let apiKey = ProcessInfo.processInfo.environment["API_KEY"]
guard let apiKey, !apiKey.isEmpty else {
    fatalError("API_KEY not configured")
}
```

## Bảo mật đường truyền

- App Transport Security (ATS) được thực thi theo mặc định — không tắt nó
- Dùng certificate pinning cho các endpoint quan trọng
- Validate mọi chứng chỉ (certificate) của server

## Kiểm tra đầu vào (Input Validation)

- Sanitize mọi đầu vào của người dùng trước khi hiển thị để ngăn injection
- Dùng `URL(string:)` kèm validate thay vì force-unwrap
- Validate dữ liệu từ nguồn bên ngoài (API, deep link, pasteboard) trước khi xử lý
