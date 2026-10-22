---
description: Đánh dấu epic ở trạng thái đã yêu cầu review, đã duyệt hoặc cần chỉnh sửa.
---

# /epic-review

Điều phối trạng thái review cho một epic issue.

```bash
node scripts/github-coordination.js review <issue-number> --repo <owner/repo> --review approved
```

Việc này làm gì:

1. Cập nhật trạng thái review trong khối điều phối.
2. Đồng bộ các label review lên GitHub.
3. Ghi lại kết quả review trong một comment kiểm toán.
4. Giữ cache cục bộ khớp với nội dung issue.

Alias tương thích:

- `/review-pr`
- `/code-review`
