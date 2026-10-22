---
paths:
  - "**/*.kt"
  - "**/*.kts"
  - "**/build.gradle.kts"
---
# Hook cho Kotlin

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung dành riêng cho Kotlin.

## Hook PostToolUse

Cấu hình trong `~/.claude/settings.json`:

- **ktfmt/ktlint**: Tự động format các file `.kt` và `.kts` sau khi sửa
- **detekt**: Chạy phân tích tĩnh sau khi sửa file Kotlin
- **./gradlew build**: Xác minh biên dịch sau khi thay đổi
