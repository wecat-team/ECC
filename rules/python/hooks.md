---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Hook cho Python

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung dành riêng cho Python.

## Hook PostToolUse

Cấu hình trong `~/.claude/settings.json`:

- **black/ruff**: Tự động format các file `.py` sau khi sửa
- **mypy/pyright**: Chạy kiểm tra type sau khi sửa các file `.py`

## Cảnh báo

- Cảnh báo về các câu lệnh `print()` trong file đã sửa (dùng module `logging` thay thế)
