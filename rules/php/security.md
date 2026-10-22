---
paths:
  - "**/*.php"
  - "**/composer.lock"
  - "**/composer.json"
---
# Bảo mật PHP

> File này mở rộng [common/security.md](../common/security.md) với nội dung dành riêng cho PHP.

## Input và Output

- Validate input của request tại ranh giới framework (`FormRequest`, Symfony Validator, hoặc validation DTO tường minh).
- Mặc định escape output trong template; coi việc render HTML thô là ngoại lệ phải được biện minh.
- KHÔNG BAO GIỜ tin query param, cookie, header hay metadata của file upload khi chưa validate.

## An toàn Database

- Dùng prepared statement (`PDO`, Doctrine, query builder của Eloquent) cho mọi truy vấn động.
- Tránh dựng SQL bằng nối chuỗi trong controller/view.
- Giới hạn mass-assignment của ORM một cách cẩn thận và dùng whitelist cho các field được phép ghi.

## Secret và Dependency

- Nạp secret từ biến môi trường hoặc secret manager, KHÔNG BAO GIỜ từ các file config được commit.
- Chạy `composer audit` trong CI và xem xét độ tin cậy của maintainer package mới trước khi thêm dependency.
- Ghim major version một cách có chủ đích và loại bỏ nhanh các package đã bị bỏ rơi.

## An toàn Auth và Session

- Dùng `password_hash()` / `password_verify()` để lưu mật khẩu.
- Tạo lại session identifier sau khi xác thực và khi thay đổi quyền.
- Ép buộc bảo vệ CSRF cho các web request làm thay đổi state.

## Tham chiếu

Xem skill: `laravel-security` để có hướng dẫn bảo mật riêng cho Laravel.
