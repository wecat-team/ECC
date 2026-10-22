---
paths:
  - "**/*.swift"
  - "**/Package.swift"
---
# Hook Swift

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung riêng cho Swift.

## Hook PostToolUse

Cấu hình trong `~/.claude/settings.json`:

- **SwiftFormat**: Tự động định dạng các file `.swift` sau khi sửa
- **SwiftLint**: Chạy kiểm tra lint sau khi sửa các file `.swift`
- **swift build**: Kiểm tra type cho các package đã sửa sau khi chỉnh sửa

## Cảnh báo

Đánh dấu các câu lệnh `print()` — hãy dùng `os.Logger` hoặc structured logging thay thế cho code production.
