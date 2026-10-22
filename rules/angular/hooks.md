---
paths:
  - "**/*.component.ts"
  - "**/*.component.html"
  - "**/*.service.ts"
  - "**/*.directive.ts"
  - "**/*.pipe.ts"
  - "**/*.spec.ts"
---
# Hook cho Angular

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung dành riêng cho Angular.

## Hook PostToolUse

Cấu hình trong `~/.claude/settings.json`:

- **Prettier**: Tự động format file `.ts` và `.html` sau khi sửa
- **ESLint / ng lint**: Chạy `ng lint` sau khi sửa source Angular để bắt lỗi dùng decorator sai, lỗi template và vi phạm style
- **Kiểm tra TypeScript**: Chạy `tsc --noEmit` sau khi sửa file `.ts`
- **Kiểm tra build**: Chạy `ng build` sau khi sinh hoặc thay đổi đáng kể code Angular để phát hiện sớm lỗi template và lỗi type

## Hook Stop

- **Lint audit**: Chạy `ng lint` trên các file đã sửa trước khi kết thúc phiên để bắt mọi vi phạm còn tồn đọng
