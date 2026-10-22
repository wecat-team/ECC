---
description: Publish một cập nhật epic đã được validate trở lại issue và cache cục bộ.
---

# /epic-publish

Publish một cập nhật điều phối đã được validate lên GitHub.

```bash
node scripts/github-coordination.js publish <issue-number> --repo <owner/repo>
```

Việc này làm gì:

1. Validate lại epic trước khi publish.
2. Cập nhật khối điều phối trong nội dung issue.
3. Thêm một comment publish ngắn gọn.
4. Ghi lại snapshot cục bộ cuối cùng.

Alias tương thích:

- `/pr`
- `/prp-pr`
