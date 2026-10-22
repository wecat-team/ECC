---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---
# Hook cho Go

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung dành riêng cho Go.

## Hook PostToolUse

Cấu hình trong `~/.claude/settings.json`:

- **gofmt/goimports**: Tự động format các file `.go` sau khi sửa
- **go vet**: Chạy phân tích tĩnh sau khi sửa các file `.go`
- **staticcheck**: Chạy các kiểm tra tĩnh mở rộng trên các package đã sửa
