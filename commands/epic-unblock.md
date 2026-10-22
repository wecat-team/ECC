---
description: Quét các epic issue đang bị chặn và mở lại bất kỳ epic nào có dependency đã đóng.
---

# /epic-unblock

Quét các epic đang bị chặn mà các dependency đã khai báo đều đã hoàn thành.

```bash
node scripts/github-coordination.js unblock --repo <owner/repo>
```

Việc này làm gì:

1. Quét các epic issue trong repo.
2. Kiểm tra danh sách dependency của từng epic đang bị chặn.
3. Chuyển các epic đã hoàn toàn hết bị chặn sang trạng thái ready.
4. Cập nhật label, comment và snapshot cục bộ.

Alias tương thích:

- `/loop-status`
