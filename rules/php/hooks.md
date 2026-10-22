---
paths:
  - "**/*.php"
  - "**/composer.json"
  - "**/phpstan.neon"
  - "**/phpstan.neon.dist"
  - "**/psalm.xml"
---
# Hook cho PHP

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung dành riêng cho PHP.

## Hook PostToolUse

Cấu hình trong `~/.claude/settings.json`:

- **Pint / PHP-CS-Fixer**: Tự động format các file `.php` đã sửa.
- **PHPStan / Psalm**: Chạy phân tích tĩnh sau khi sửa PHP trong các codebase có định kiểu.
- **PHPUnit / Pest**: Chạy các test nhắm mục tiêu cho file hoặc module đã chạm tới khi chỉnh sửa ảnh hưởng đến hành vi.

## Cảnh báo

- Cảnh báo khi còn sót `var_dump`, `dd`, `dump` hoặc `die()` trong các file đã sửa.
- Cảnh báo khi file PHP đã sửa thêm raw SQL hoặc vô hiệu hóa bảo vệ CSRF/session.
