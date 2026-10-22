---
name: projects
description: Liệt kê các project đã biết và thống kê instinct của từng project
command: true
---

# Lệnh Projects

Liệt kê các mục trong registry project cùng số lượng instinct/observation của từng project cho continuous-learning-v2.

## Triển khai

Chạy instinct CLI bằng đường dẫn plugin root:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" projects
```

Hoặc nếu `CLAUDE_PLUGIN_ROOT` chưa được đặt (cài đặt thủ công):

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py projects
```

## Cách dùng

```bash
/projects
```

## Cần làm gì

1. Đọc `~/.claude/homunculus/projects.json`
2. Với mỗi project, hiển thị:
   - Tên project, id, root, remote
   - Số lượng instinct cá nhân (personal) và kế thừa (inherited)
   - Số lượng sự kiện observation
   - Mốc thời gian lần cuối thấy (last seen)
3. Hiển thị thêm tổng số instinct global
