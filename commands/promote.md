---
name: promote
description: Nâng cấp các instinct phạm vi project lên phạm vi global
command: true
---

# Lệnh Promote

Nâng cấp (promote) instinct từ phạm vi project lên phạm vi global trong continuous-learning-v2.

## Triển khai

Chạy instinct CLI bằng đường dẫn plugin root:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" promote [instinct-id] [--force] [--dry-run]
```

Hoặc nếu `CLAUDE_PLUGIN_ROOT` chưa được đặt (cài đặt thủ công):

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py promote [instinct-id] [--force] [--dry-run]
```

## Cách dùng

```bash
/promote                      # Auto-detect promotion candidates
/promote --dry-run            # Preview auto-promotion candidates
/promote --force              # Promote all qualified candidates without prompt
/promote grep-before-edit     # Promote one specific instinct from current project
```

## Cần làm gì

1. Phát hiện project hiện tại
2. Nếu có `instinct-id`, chỉ promote instinct đó (nếu nó tồn tại trong project hiện tại)
3. Nếu không, tìm các ứng viên xuyên project thỏa mãn:
   - Xuất hiện trong ít nhất 2 project
   - Đạt ngưỡng confidence
4. Ghi các instinct đã promote vào `~/.claude/homunculus/instincts/personal/` với `scope: global`
