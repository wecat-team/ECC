---
description: Đồng bộ tài liệu từ các file nguồn sự thật (source-of-truth) như script, schema, route và export.
---

# Update Documentation

Đồng bộ tài liệu với codebase, tạo ra từ các file nguồn sự thật.

## Bước 1: Xác định các nguồn sự thật

| Nguồn | Tạo ra |
|--------|-----------|
| Script trong `package.json` | Tài liệu tham chiếu các lệnh có sẵn |
| `.env.example` | Tài liệu biến môi trường |
| `openapi.yaml` / các file route | Tài liệu tham chiếu API endpoint |
| Export của source code | Tài liệu API public |
| `Dockerfile` / `docker-compose.yml` | Tài liệu thiết lập hạ tầng |

## Bước 2: Tạo tài liệu tham chiếu Script

1. Đọc `package.json` (hoặc `Makefile`, `Cargo.toml`, `pyproject.toml`)
2. Trích xuất tất cả script/lệnh cùng mô tả của chúng
3. Tạo bảng tham chiếu:

```markdown
| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server with hot reload |
| `npm run build` | Production build with type checking |
| `npm test` | Run test suite with coverage |
```

## Bước 3: Tạo tài liệu Biến môi trường

1. Đọc `.env.example` (hoặc `.env.template`, `.env.sample`)
2. Trích xuất tất cả biến cùng mục đích của chúng
3. Phân loại bắt buộc (required) và tùy chọn (optional)
4. Ghi lại định dạng mong đợi và các giá trị hợp lệ

```markdown
| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `DATABASE_URL` | Yes | PostgreSQL connection string | `postgres://user:pass@host:5432/db` |
| `LOG_LEVEL` | No | Logging verbosity (default: info) | `debug`, `info`, `warn`, `error` |
```

## Bước 4: Cập nhật Contributing Guide

Tạo hoặc cập nhật `docs/CONTRIBUTING.md` với:
- Thiết lập môi trường phát triển (điều kiện tiên quyết, các bước cài đặt)
- Các script có sẵn và mục đích của chúng
- Quy trình kiểm thử (cách chạy, cách viết test mới)
- Thực thi code style (linter, formatter, pre-commit hook)
- Checklist khi gửi PR

## Bước 5: Cập nhật Runbook

Tạo hoặc cập nhật `docs/RUNBOOK.md` với:
- Quy trình deploy (từng bước)
- Endpoint health check và giám sát
- Các sự cố thường gặp và cách khắc phục
- Quy trình rollback
- Cảnh báo và đường leo thang (escalation)

## Bước 6: Kiểm tra độ lỗi thời

1. Tìm các file tài liệu không được sửa trong 90+ ngày
2. Đối chiếu chéo với các thay đổi source code gần đây
3. Đánh dấu các tài liệu có khả năng lỗi thời để review thủ công

## Bước 7: Hiển thị tóm tắt

```
Documentation Update
──────────────────────────────
Updated:  docs/CONTRIBUTING.md (scripts table)
Updated:  docs/ENV.md (3 new variables)
Flagged:  docs/DEPLOY.md (142 days stale)
Skipped:  docs/API.md (no changes detected)
──────────────────────────────
```

## Quy tắc

- **Nguồn sự thật duy nhất**: LUÔN LUÔN tạo từ code, KHÔNG BAO GIỜ chỉnh sửa thủ công các phần được tạo tự động
- **Giữ nguyên các phần thủ công**: Chỉ cập nhật các phần được tạo; để nguyên văn xuôi viết tay
- **Đánh dấu nội dung được tạo**: Dùng marker `<!-- AUTO-GENERATED -->` bao quanh các phần được tạo
- **Không tự ý tạo tài liệu**: Chỉ tạo file tài liệu mới nếu lệnh yêu cầu tường minh
