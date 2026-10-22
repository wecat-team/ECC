---
description: Nhận trợ giúp về hệ thống hookify
---

Hiển thị tài liệu hookify đầy đủ.

## Tổng quan hệ thống hook

Hookify tạo các file rule tích hợp với hệ thống hook của Claude Code để ngăn các hành vi không mong muốn.
Runtime tích hợp sẵn của ECC tự động nạp các rule này khi plugin hook
được bật; không cần cài một plugin Hookify riêng.

### Các loại event

- `bash`: kích hoạt khi dùng tool Bash và khớp theo pattern của command
- `file`: kích hoạt khi dùng tool Write/Edit và khớp theo đường dẫn file
- `stop`: kích hoạt sau mỗi phản hồi của Claude
- `prompt`: kích hoạt khi người dùng gửi tin nhắn và khớp theo pattern của input
- `all`: kích hoạt trên mọi event

### Định dạng file rule

Các file được lưu dưới dạng `.claude/hookify.{name}.local.md`:

```yaml
---
name: descriptive-name
enabled: true
event: bash|file|stop|prompt|all
action: block|warn
pattern: "regex pattern to match"
---
Message to display when rule triggers.
Supports multiple lines.
```

### Các command

- `/hookify [description]` tạo rule mới và tự động phân tích hội thoại khi không có mô tả
- `/hookify-list` liệt kê các rule đã cấu hình
- `/hookify-configure` bật hoặc tắt các rule

### Mẹo về pattern

- dùng cú pháp regex
- với `bash`, khớp theo toàn bộ chuỗi command
- với `file`, khớp theo đường dẫn file
- test pattern trước khi deploy
- tránh quantifier lồng nhau như `(a+)+`; runtime sẽ từ chối các regex không an toàn
- mỗi lần đánh giá regex cũng có timeout cứng 25 ms
- rule bị lỗi định dạng hoặc quá lớn sẽ fail open kèm chẩn đoán, để một rule cục bộ hỏng không thể vô hiệu hóa toàn bộ hook
- Rule cục bộ được Git theo dõi cần có sự chấp thuận tường minh `ECC_HOOKIFY_ALLOW_TRACKED=1`

### Hành vi của action

- `warn` thêm thông điệp của rule vào context của Claude và cho phép tiếp tục xử lý
- `block` từ chối các hành động shell/file khớp trước khi thực thi
- `block` trên các event prompt, post-tool hoặc stop dùng quyết định block có cấu trúc của event đó
- rule stop bị bỏ qua khi `stop_hook_active` đã là true để tránh vòng lặp
