---
name: prune
description: Xóa các instinct pending cũ hơn 30 ngày chưa từng được promote. Lớp bọc CLI mỏng cho lệnh prune của instinct-cli.py trong continuous-learning-v2; dùng để dọn các instinct pending cũ chưa từng được review hoặc promote.
command: true
---

# Dọn dẹp Pending Instinct

Xóa các instinct pending đã hết hạn, được tạo tự động nhưng chưa từng được review hoặc promote.

## Triển khai

Chạy instinct CLI bằng đường dẫn plugin root:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" prune
```

Hoặc nếu `CLAUDE_PLUGIN_ROOT` chưa được đặt (cài đặt thủ công):

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py prune
```

## Cách dùng

```
/prune                    # Delete instincts older than 30 days
/prune --max-age 60      # Custom age threshold (days)
/prune --dry-run         # Preview without deleting
```
