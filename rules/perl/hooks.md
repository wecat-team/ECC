---
paths:
  - "**/*.pl"
  - "**/*.pm"
  - "**/*.t"
  - "**/*.psgi"
  - "**/*.cgi"
---
# Hook cho Perl

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung dành riêng cho Perl.

## Hook PostToolUse

Cấu hình trong `~/.claude/settings.json`:

- **perltidy**: Tự động format các file `.pl` và `.pm` sau khi sửa
- **perlcritic**: Chạy kiểm tra lint sau khi sửa các file `.pm`

## Cảnh báo

- Cảnh báo về `print` trong các file `.pm` không phải script — dùng `say` hoặc một module logging (ví dụ `Log::Any`)
