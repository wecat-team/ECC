---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# Hook TypeScript/JavaScript

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung riêng cho TypeScript/JavaScript.

## Hook PostToolUse

Cấu hình trong `~/.claude/settings.json`:

- **Prettier**: Tự động định dạng file JS/TS sau khi sửa
- **TypeScript check**: Chạy `tsc` sau khi sửa file `.ts`/`.tsx`
- **console.log warning**: Cảnh báo về `console.log` trong các file đã sửa

## Hook Stop

- **console.log audit**: Kiểm tra mọi file đã sửa xem có `console.log` không trước khi session kết thúc
