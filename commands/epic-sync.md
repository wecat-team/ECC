---
description: Đồng bộ nội dung epic issue, label và snapshot điều phối cục bộ từ GitHub.
---

# /epic-sync

Chạy một lần đồng bộ xác định (deterministic) cho các epic issue.

```bash
node scripts/github-coordination.js sync --repo <owner/repo>
```

Việc này làm gì:

1. Đọc nội dung issue làm trạng thái epic chuẩn.
2. Đối chiếu khối điều phối với các label.
3. Ghi một snapshot cục bộ mới cho từng epic issue.
4. Giữ cache SQLite khớp với GitHub.

Alias tương thích:

- `/projects`
- `/work-items sync-github`
