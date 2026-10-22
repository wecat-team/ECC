---
paths:
  - "**/*.php"
  - "**/composer.json"
---
# Pattern PHP

> File này mở rộng [common/patterns.md](../common/patterns.md) với nội dung dành riêng cho PHP.

## Controller mỏng, Service tường minh

- Giữ controller tập trung vào tầng truyền tải: auth, validation, serialization, status code.
- Chuyển business rule vào các application/domain service dễ test mà không cần khởi động HTTP.

## DTO và Value Object

- Thay các associative array nặng về cấu trúc bằng DTO cho request, command và payload API bên ngoài.
- Dùng value object cho tiền tệ, định danh, khoảng ngày và các khái niệm có ràng buộc khác.

## Dependency Injection

- Phụ thuộc vào interface hoặc các service contract hẹp, không phụ thuộc vào global của framework.
- Truyền các collaborator qua constructor để service test được mà không cần tra cứu service-locator.

## Ranh giới

- Cô lập ORM model khỏi các quyết định domain khi tầng model đang làm nhiều hơn việc persistence.
- Bọc SDK bên thứ ba sau các adapter nhỏ để phần còn lại của codebase phụ thuộc vào contract của bạn, không phải của họ.

## Tham chiếu

Xem skill: `api-design` để có quy ước endpoint và hướng dẫn về hình dạng response.
Xem skill: `laravel-patterns` để có hướng dẫn kiến trúc riêng cho Laravel.
