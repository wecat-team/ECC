---
paths:
  - "**/*.java"
  - "**/pom.xml"
  - "**/build.gradle"
  - "**/build.gradle.kts"
---
# Hook cho Java

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung dành riêng cho Java.

## Hook PostToolUse

Cấu hình trong `~/.claude/settings.json`:

- **google-java-format**: Tự động format các file `.java` sau khi sửa
- **checkstyle**: Chạy kiểm tra style sau khi sửa file Java
- **./mvnw compile** hoặc **./gradlew compileJava**: Xác minh biên dịch sau khi thay đổi
