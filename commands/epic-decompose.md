---
description: Chia một epic thành các task con mà không tạo branch cho task.
---

# /epic-decompose

Đối chiếu (reconcile) việc phân rã task cho một epic issue.

```bash
node scripts/github-coordination.js decompose <issue-number> --repo <owner/repo>
```

Việc này làm gì:

1. Đọc nội dung epic issue để lấy checklist task và các tham chiếu dependency.
2. Lưu kết quả phân rã vào khối điều phối.
3. Không đưa task branch vào workflow.
4. Thêm một comment kiểm toán ngắn gọn.

Alias tương thích:

- `/plan`
- `/prp-plan`
