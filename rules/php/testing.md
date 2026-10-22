---
paths:
  - "**/*.php"
  - "**/phpunit.xml"
  - "**/phpunit.xml.dist"
  - "**/composer.json"
---
# Kiểm thử PHP

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung dành riêng cho PHP.

## Framework

Dùng **PHPUnit** làm test framework mặc định. Nếu dự án đã cấu hình **Pest**, hãy ưu tiên Pest cho test mới và tránh trộn lẫn các framework.

## Coverage

```bash
vendor/bin/phpunit --coverage-text
# or
vendor/bin/pest --coverage
```

Ưu tiên **pcov** hoặc **Xdebug** trong CI, và đặt ngưỡng coverage trong CI thay vì để nó thành kiến thức truyền miệng.

## Tổ chức Test

- Tách unit test nhanh khỏi integration test framework/database.
- Dùng factory/builder cho fixture thay vì các array viết tay lớn.
- Giữ test HTTP/controller tập trung vào tầng truyền tải và validation; chuyển business rule sang test ở cấp service.

## Inertia

Nếu dự án dùng Inertia.js, ưu tiên `assertInertia` với `AssertableInertia` để xác minh tên component và props thay vì assertion JSON thô.

## Tham chiếu

Xem skill: `tdd-workflow` để có vòng lặp RED -> GREEN -> REFACTOR áp dụng cho toàn repo.
Xem skill: `laravel-tdd` để có các pattern kiểm thử riêng cho Laravel (PHPUnit và Pest).
