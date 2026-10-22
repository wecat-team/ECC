---
description: Tạo, xác minh hoặc liệt kê các checkpoint của workflow sau khi chạy các kiểm tra xác minh.
---

# Lệnh Checkpoint

Tạo hoặc xác minh một checkpoint trong workflow của bạn.

## Cách dùng

`/checkpoint [create|verify|list] [name]`

## Tạo checkpoint

Khi tạo một checkpoint:

1. Chạy `/verify quick` để đảm bảo trạng thái hiện tại sạch
2. Tạo một git stash hoặc commit với tên checkpoint
3. Ghi checkpoint vào `.claude/checkpoints.log`:

```bash
echo "$(date +%Y-%m-%d-%H:%M) | $CHECKPOINT_NAME | $(git rev-parse --short HEAD)" >> .claude/checkpoints.log
```

4. Báo cáo checkpoint đã được tạo

## Xác minh checkpoint

Khi xác minh so với một checkpoint:

1. Đọc checkpoint từ log
2. So sánh trạng thái hiện tại với checkpoint:
   - Các file được thêm kể từ checkpoint
   - Các file được sửa kể từ checkpoint
   - Tỷ lệ test pass hiện tại so với lúc đó
   - Coverage hiện tại so với lúc đó

3. Báo cáo:
```
CHECKPOINT COMPARISON: $NAME
============================
Files changed: X
Tests: +Y passed / -Z failed
Coverage: +X% / -Y%
Build: [PASS/FAIL]
```

## Liệt kê checkpoint

Hiển thị tất cả checkpoint kèm:
- Tên
- Timestamp
- Git SHA
- Trạng thái (current, behind, ahead)

## Workflow

Luồng checkpoint điển hình:

```
[Start] --> /checkpoint create "feature-start"
   |
[Implement] --> /checkpoint create "core-done"
   |
[Test] --> /checkpoint verify "core-done"
   |
[Refactor] --> /checkpoint create "refactor-done"
   |
[PR] --> /checkpoint verify "feature-start"
```

## Đối số

$ARGUMENTS:
- `create <name>` - Tạo checkpoint có tên
- `verify <name>` - Xác minh so với checkpoint có tên
- `list` - Hiển thị tất cả checkpoint
- `clear` - Xóa các checkpoint cũ (giữ lại 5 cái gần nhất)
