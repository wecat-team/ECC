---
name: instinct-import
description: Import các instinct từ file hoặc URL vào phạm vi project/global
command: true
---

# Lệnh Instinct Import

## Triển khai

Chạy instinct CLI bằng đường dẫn gốc của plugin:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" import <file-or-url> [--dry-run] [--force] [--min-confidence 0.7] [--scope project|global]
```

Hoặc nếu `CLAUDE_PLUGIN_ROOT` chưa được đặt (cài đặt thủ công):

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py import <file-or-url>
```

Import các instinct từ đường dẫn file cục bộ hoặc URL HTTP(S).

## Cách dùng

```
/instinct-import team-instincts.yaml
/instinct-import https://github.com/org/repo/instincts.yaml
/instinct-import team-instincts.yaml --dry-run
/instinct-import team-instincts.yaml --scope global --force
```

## Cần làm gì

1. Lấy file instinct (đường dẫn cục bộ hoặc URL)
2. Parse và validate định dạng
3. Kiểm tra trùng lặp với các instinct hiện có
4. Merge hoặc thêm instinct mới
5. Lưu vào thư mục instinct kế thừa (inherited):
   - Phạm vi dự án: `~/.claude/homunculus/projects/<project-id>/instincts/inherited/`
   - Phạm vi global: `~/.claude/homunculus/instincts/inherited/`

## Quy trình import

```
 Importing instincts from: team-instincts.yaml
================================================

Found 12 instincts to import.

Analyzing conflicts...

## New Instincts (8)
These will be added:
  ✓ use-zod-validation (confidence: 0.7)
  ✓ prefer-named-exports (confidence: 0.65)
  ✓ test-async-functions (confidence: 0.8)
  ...

## Duplicate Instincts (3)
Already have similar instincts:
  WARNING: prefer-functional-style
     Local: 0.8 confidence, 12 observations
     Import: 0.7 confidence
     → Keep local (higher confidence)

  WARNING: test-first-workflow
     Local: 0.75 confidence
     Import: 0.9 confidence
     → Update to import (higher confidence)

Import 8 new, update 1?
```

## Hành vi merge

Khi import một instinct có ID đã tồn tại:
- Bản import có độ tin cậy cao hơn trở thành ứng viên cập nhật
- Bản import có độ tin cậy bằng/thấp hơn bị bỏ qua
- Người dùng xác nhận, trừ khi dùng `--force`

## Theo dõi nguồn

Các instinct được import được đánh dấu bằng:
```yaml
source: inherited
scope: project
imported_from: "team-instincts.yaml"
project_id: "a1b2c3d4e5f6"
project_name: "my-project"
```

## Flag

- `--dry-run`: Xem trước mà không import
- `--force`: Bỏ qua bước hỏi xác nhận
- `--min-confidence <n>`: Chỉ import các instinct trên ngưỡng
- `--scope <project|global>`: Chọn phạm vi đích (mặc định: `project`)

## Output

Sau khi import:
```
PASS: Import complete!

Added: 8 instincts
Updated: 1 instinct
Skipped: 3 instincts (equal/higher confidence already exists)

New instincts saved to: ~/.claude/homunculus/instincts/inherited/

Run /instinct-status to see all instincts.
```
