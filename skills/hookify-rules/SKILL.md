---
name: hookify-rules
description: "Tạo và cấu hình hookify rule — các file markdown có YAML frontmatter, khớp với sự kiện bash, file, prompt hoặc stop bằng regex hoặc điều kiện và hiển thị thông báo warn/block cho agent. Dùng khi tạo hookify rule, viết cú pháp hook rule, cấu hình hookify, hoặc thêm các guardrail theo pattern như chặn lệnh nguy hiểm, chỉnh sửa .env hoặc debug code."
---

# Viết Hookify Rule

## Tổng quan

ECC đánh giá các Hookify rule cục bộ của dự án bằng runtime Node tích hợp sẵn. Không cần cài thêm plugin Hookify riêng hay Python khi các ECC hook được bật.

Hookify rule là các file markdown có YAML frontmatter, định nghĩa các pattern cần theo dõi và thông báo hiển thị khi các pattern đó khớp. Rule được lưu trong các file `.claude/hookify.{rule-name}.local.md`.

## Định dạng file rule

### Cấu trúc cơ bản

```markdown
---
name: rule-identifier
enabled: true
event: bash|file|stop|prompt|all
pattern: regex-pattern-here
---

Message to show Claude when this rule triggers.
Can include markdown formatting, warnings, suggestions, etc.
```

### Các trường frontmatter

| Trường | Bắt buộc | Giá trị | Mô tả |
|-------|----------|--------|-------------|
| name | Có | chuỗi kebab-case | Định danh duy nhất (bắt đầu bằng động từ: warn-*, block-*, require-*) |
| enabled | Có | true/false | Bật/tắt mà không cần xóa |
| event | Có | bash/file/stop/prompt/all | Hook event nào kích hoạt rule này |
| action | Không | warn/block | warn (mặc định) hiển thị thông báo; block ngăn thao tác |
| pattern | Có* | chuỗi regex | Pattern để khớp (*hoặc dùng conditions cho các rule phức tạp) |

### Định dạng nâng cao (Nhiều điều kiện)

```markdown
---
name: warn-env-api-keys
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.env$
  - field: new_text
    operator: contains
    pattern: API_KEY
---

You're adding an API key to a .env file. Ensure this file is in .gitignore!
```

**Các trường điều kiện theo event:**
- bash: `command`
- file: `file_path`, `new_text`, `old_text`, `content`
- prompt: `user_prompt`

**Toán tử:** `regex_match`, `contains`, `equals`, `not_contains`, `starts_with`, `ends_with`

Tất cả điều kiện phải khớp thì rule mới được kích hoạt.

## Hướng dẫn các loại Event

### Event bash
Khớp với các pattern lệnh Bash:
- Lệnh nguy hiểm: `rm\s+-rf`, `dd\s+if=`, `mkfs`
- Leo thang đặc quyền: `sudo\s+`, `su\s+`
- Vấn đề về quyền: `chmod\s+777`

### Event file
Khớp với các thao tác Edit/Write/MultiEdit:
- Debug code: `console\.log\(`, `debugger`
- Rủi ro bảo mật: `eval\(`, `innerHTML\s*=`
- File nhạy cảm: `\.env$`, `credentials`, `\.pem$`

### Event stop
Kiểm tra khi hoàn thành và nhắc nhở. Pattern `.*` luôn khớp.

### Event prompt
Khớp với nội dung prompt của người dùng để thực thi workflow.

## Mẹo viết pattern

### Cơ bản về Regex
- Escape ký tự đặc biệt: `.` thành `\.`, `(` thành `\(`
- `\s` khoảng trắng, `\d` chữ số, `\w` ký tự chữ
- `+` một hoặc nhiều, `*` không hoặc nhiều, `?` tùy chọn
- `|` toán tử OR

### Lỗi thường gặp
- **Quá rộng**: `log` khớp "login", "dialog" — hãy dùng `console\.log\(`
- **Quá cụ thể**: `rm -rf /tmp` — hãy dùng `rm\s+-rf`
- **Escape trong YAML**: Dùng pattern không có dấu nháy; chuỗi có dấu nháy cần `\\s`

### Kiểm thử
```bash
python3 -c "import re; print(re.search(r'your_pattern', 'test text'))"
```

Tránh các quantifier lồng nhau như `(a+)+`. Runtime từ chối các pattern có dạng
backtracking thảm họa (catastrophic backtracking) phổ biến vì các rule chạy đồng bộ
trong đường dẫn hook, và mỗi lần đánh giá regex có timeout cứng 25 ms. Các rule cục bộ
không hợp lệ, là symlink hoặc quá lớn sẽ fail open và phát ra một
thông báo chẩn đoán mà không vô hiệu hóa các Hookify rule khác.

Các rule cục bộ được git theo dõi (git-tracked) bị tắt theo mặc định. Chỉ đặt
`ECC_HOOKIFY_ALLOW_TRACKED=1` sau khi đã review các file đó; các rule thông thường
nằm trong gitignore được tạo cục bộ vẫn hoạt động mà không cần override này.

## Hành vi runtime

- `warn` chèn thông báo như context bổ sung theo từng event cụ thể và không chặn.
- `block` từ chối các lệnh gọi Bash, PowerShell, Write, Edit hoặc MultiEdit khớp rule trước khi thực thi.
- Với các event prompt, post-tool và stop, `block` dùng quyết định block có cấu trúc của Claude Code.
- Các stop rule bỏ qua các event `stop_hook_active` đệ quy để ngăn vòng lặp tiếp tục vô hạn.

## Tổ chức file

- **Vị trí**: thư mục `.claude/` ở thư mục gốc dự án
- **Đặt tên**: `.claude/hookify.{descriptive-name}.local.md`
- **Gitignore**: Thêm `.claude/*.local.md` vào `.gitignore`

## Lệnh

- `/hookify [description]` - Tạo rule mới (tự động phân tích cuộc hội thoại nếu không có đối số)
- `/hookify-list` - Xem tất cả rule dạng bảng
- `/hookify-configure` - Bật/tắt rule một cách tương tác
- `/hookify-help` - Tài liệu đầy đủ

## Tham khảo nhanh

Rule tối thiểu khả dụng:
```markdown
---
name: my-rule
enabled: true
event: bash
pattern: dangerous_command
---
Warning message here
```
