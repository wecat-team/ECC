---
description: Tạo hook để ngăn các hành vi không mong muốn từ việc phân tích hội thoại hoặc chỉ dẫn tường minh. Dùng để sinh một file rule hook mới từ phân tích hội thoại hoặc một hành vi được mô tả; skill hookify-rules bao quát cú pháp và pattern của rule hookify để viết hoặc chỉnh sửa rule trực tiếp.
---

Tạo các rule hook để ngăn những hành vi không mong muốn của Claude Code bằng cách phân tích các pattern trong hội thoại hoặc chỉ dẫn tường minh của người dùng.

## Cách dùng

`/hookify [description of behavior to prevent]`

Nếu không có đối số, hãy phân tích hội thoại hiện tại để tìm các hành vi đáng ngăn chặn.

## Workflow

### Bước 1: Thu thập thông tin hành vi

- Có đối số: parse mô tả của người dùng về hành vi không mong muốn
- Không có đối số: dùng agent `conversation-analyzer` để tìm:
  - các lần chỉnh sửa tường minh
  - phản ứng bực bội trước các lỗi lặp lại
  - các thay đổi bị hoàn tác
  - các vấn đề tương tự lặp lại

### Bước 2: Trình bày phát hiện

Hiển thị cho người dùng:

- mô tả hành vi
- loại event đề xuất
- pattern hoặc matcher đề xuất
- action đề xuất

### Bước 3: Sinh file rule

Với mỗi rule được duyệt, tạo một file tại `.claude/hookify.{name}.local.md`:

```yaml
---
name: rule-name
enabled: true
event: bash|file|stop|prompt|all
action: block|warn
pattern: "regex pattern"
---
Message shown when rule triggers.
```

### Bước 4: Xác nhận

Báo cáo các rule đã tạo và cách quản lý chúng bằng `/hookify-list` và `/hookify-configure`.
Runtime hook tích hợp sẵn của ECC tự động thực thi các rule đang bật; không cần
plugin Hookify riêng hay Python runtime.
