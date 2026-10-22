---
description: Nhận (claim) một epic issue, đóng dấu trạng thái điều phối và đồng bộ quyền sở hữu cục bộ.
---

# /epic-claim

Nhận một epic issue làm nguồn sự thật (source of truth) cho một đơn vị công việc.

Dùng script điều phối:

```bash
node scripts/github-coordination.js claim <issue-number> --repo <owner/repo> --actor <login>
```

Việc này làm gì:

1. Tải nội dung issue và khối điều phối (coordination block).
2. Đánh dấu epic là đã được claim trong trạng thái issue trên GitHub.
3. Cập nhật label và cache SQLite cục bộ.
4. Thêm một comment kiểm toán (audit) cho việc claim.

Alias tương thích:

- `/orch-add-feature`
- `/orch-change-feature`
- `/prp-implement`
