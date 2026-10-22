---
description: Liệt kê tất cả rule hookify đã cấu hình
---

Tìm và hiển thị tất cả rule hookify dưới dạng bảng có định dạng.

## Các bước

1. Tìm tất cả file `.claude/hookify.*.local.md`
2. Đọc frontmatter của từng file:
   - `name`
   - `enabled`
   - `event`
   - `action`
   - `pattern`
3. Hiển thị dưới dạng bảng:

| Rule | Enabled | Event | Pattern | File |
|------|---------|-------|---------|------|

4. Hiển thị số lượng rule và nhắc người dùng rằng `/hookify-configure` có thể thay đổi trạng thái sau này.
