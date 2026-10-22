---
description: Quét cấu trúc project và tạo codemap kiến trúc tiết kiệm token.
---

# Update Codemaps

Phân tích cấu trúc codebase và tạo tài liệu kiến trúc tiết kiệm token.

## Bước 1: Quét cấu trúc project

1. Xác định loại project (monorepo, ứng dụng đơn, thư viện, microservice)
2. Tìm tất cả thư mục source (src/, lib/, app/, packages/)
3. Lập bản đồ các entry point (main.ts, index.ts, app.py, main.go, v.v.)

## Bước 2: Tạo Codemap

Tạo hoặc cập nhật codemap trong `docs/CODEMAPS/` (hoặc `.reports/codemaps/`):

| File | Nội dung |
|------|----------|
| `architecture.md` | Sơ đồ hệ thống mức cao, ranh giới service, luồng dữ liệu |
| `backend.md` | API route, chuỗi middleware, ánh xạ service → repository |
| `frontend.md` | Cây page, phân cấp component, luồng quản lý state |
| `data.md` | Bảng database, quan hệ, lịch sử migration |
| `dependencies.md` | Dịch vụ bên ngoài, tích hợp bên thứ ba, thư viện dùng chung |

### Định dạng Codemap

Mỗi codemap phải tiết kiệm token — được tối ưu cho việc AI tiêu thụ context:

```markdown
# Backend Architecture

## Routes
POST /api/users → UserController.create → UserService.create → UserRepo.insert
GET  /api/users/:id → UserController.get → UserService.findById → UserRepo.findById

## Key Files
src/services/user.ts (business logic, 120 lines)
src/repos/user.ts (database access, 80 lines)

## Dependencies
- PostgreSQL (primary data store)
- Redis (session cache, rate limiting)
- Stripe (payment processing)
```

## Bước 3: Phát hiện Diff

1. Nếu đã có codemap trước đó, tính tỷ lệ phần trăm diff
2. Nếu thay đổi > 30%, hiển thị diff và xin người dùng phê duyệt trước khi ghi đè
3. Nếu thay đổi <= 30%, cập nhật tại chỗ

## Bước 4: Thêm Metadata

Thêm header về độ mới (freshness) vào mỗi codemap:

```markdown
<!-- Generated: 2026-02-11 | Files scanned: 142 | Token estimate: ~800 -->
```

## Bước 5: Lưu báo cáo phân tích

Ghi bản tóm tắt vào `.reports/codemap-diff.txt`:
- File được thêm/xóa/sửa kể từ lần quét trước
- Dependency mới được phát hiện
- Thay đổi kiến trúc (route mới, service mới, v.v.)
- Cảnh báo lỗi thời cho tài liệu không được cập nhật trong 90+ ngày

## Mẹo

- Tập trung vào **cấu trúc mức cao**, không phải chi tiết triển khai
- Ưu tiên **đường dẫn file và signature của function** hơn các khối code đầy đủ
- Giữ mỗi codemap dưới **1000 token** để tải context hiệu quả
- Dùng sơ đồ ASCII cho luồng dữ liệu thay vì mô tả dài dòng
- Chạy sau các lần bổ sung tính năng lớn hoặc các phiên refactor
