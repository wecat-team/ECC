---
description: Validate mức độ sẵn sàng của epic, dependency và chính sách điều phối.
---

# /epic-validate

Validate một epic issue đơn lẻ trước khi publish hoặc bàn giao để review.

```bash
node scripts/github-coordination.js validate <issue-number> --repo <owner/repo>
```

Việc này kiểm tra gì:

1. Trạng thái điều phối tồn tại và parse được.
2. Trạng thái validation thỏa chính sách.
3. Các dependency đã khai báo đều đã đóng.
4. Epic sẵn sàng cho giai đoạn workflow tiếp theo.

Alias tương thích:

- `/quality-gate`
