---
description: Điều hướng các agent, skill, command, hook, install profile và tài liệu hiện có của ECC từ bề mặt repo thực tế. Đây là điểm vào dạng slash command cho việc điều hướng; skill ecc-guide cung cấp cùng bản đồ này để dùng theo yêu cầu trong hội thoại.
---

# /ecc-guide

Dùng command này như một bản đồ hội thoại về ECC. Nó giúp người dùng tìm đúng bề mặt ECC cho tác vụ của họ mà không phải đổ nguyên README hay các con số catalog đã lỗi thời.

## Cách dùng

```text
/ecc-guide
/ecc-guide setup
/ecc-guide skills
/ecc-guide commands
/ecc-guide hooks
/ecc-guide install
/ecc-guide find: <query>
/ecc-guide <feature-or-file-name>
```

## Quy tắc vận hành

1. Đọc các file hiện tại của repo trước khi trả lời khi có checkout.
2. Ưu tiên dữ liệu filesystem/catalog hiện tại hơn các con số hard-code.
3. Giữ câu trả lời đầu tiên ngắn gọn, sau đó đề xuất các hướng đi sâu cụ thể.
4. Dẫn người dùng tới các file chuẩn (canonical) thay vì sao chép các đoạn dài.
5. Không bịa ra command, skill, agent hoặc install profile không tồn tại.

## Cần kiểm tra những gì

Dùng các file sau làm bản đồ chuẩn:

- `README.md` cho đường dẫn cài đặt, hướng dẫn reset/gỡ cài đặt và định vị tổng quan
- `AGENTS.md` cho hướng dẫn dành cho contributor và cấu trúc dự án
- `agent.yaml` cho bề mặt agent và command được export
- `commands/` cho các shim slash-command đang được bảo trì
- `skills/*/SKILL.md` cho các workflow skill tái sử dụng
- `agents/*.md` cho các vai trò agent được ủy quyền
- `hooks/README.md` và `hooks/hooks.json` cho hành vi của hook
- `manifests/install-*.json` cho các module cài đặt chọn lọc, component và profile
- `scripts/ci/catalog.js --json` cho số liệu catalog trực tiếp khi chạy bên trong ECC

## Mẫu phản hồi

### Không có đối số

Đưa ra một menu gọn:

- setup và cài đặt
- chọn skill
- các shim tương thích command
- agent và ủy quyền
- hook và an toàn
- xử lý sự cố cài đặt
- tìm một tính năng cụ thể

Sau đó hỏi người dùng muốn làm gì tiếp theo.

### Tra cứu theo chủ đề

Với các chủ đề như `skills`, `commands`, `hooks`, `install` hoặc `agents`:

1. Tóm tắt bề mặt hiện tại trong 3-6 gạch đầu dòng.
2. Chỉ tới các thư mục/file chuẩn.
3. Gợi ý một hoặc hai command có thể dùng để xác minh trạng thái.
4. Tránh liệt kê đầy đủ trừ khi người dùng yêu cầu.

### Chế độ tìm kiếm

Với `find: <query>`:

1. Tìm trong các file liên quan bằng `rg`.
2. Nhóm kết quả theo bề mặt: skills, commands, agents, rules, docs, hooks.
3. Trả về các kết quả khớp mạnh nhất trước, kèm đường dẫn file.
4. Đề xuất hành động tiếp theo cho mỗi kết quả khớp.

### Tra cứu tính năng

Với một tên tính năng cụ thể:

1. Kiểm tra các đường dẫn chính xác trước, như `skills/<name>/SKILL.md`, `commands/<name>.md` và `agents/<name>.md`.
2. Nếu tra cứu chính xác thất bại, tìm bằng `rg`.
3. Giải thích tính năng làm gì, khi nào dùng và file nào là file chuẩn.
4. Chỉ nhắc tới các tính năng liên quan khi điều đó giúp giảm nhầm lẫn.

## Các command liên quan

- `/project-init` để onboarding ECC theo stack cho một dự án đích
- `/harness-audit` để chấm điểm mức độ sẵn sàng của repo một cách xác định
- `/skill-health` để kiểm tra chất lượng skill
- `/skill-create` để trích xuất một skill mới từ lịch sử git cục bộ
- `/security-scan` để review bảo mật cấu hình Claude/OpenCode
