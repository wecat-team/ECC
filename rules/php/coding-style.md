---
paths:
  - "**/*.php"
  - "**/composer.json"
---
# Phong cách code PHP

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung dành riêng cho PHP.

## Tiêu chuẩn

- Tuân theo quy ước định dạng và đặt tên **PSR-12**.
- Ưu tiên `declare(strict_types=1);` trong code ứng dụng.
- Dùng scalar type hint, return type và typed property ở mọi nơi mà code mới cho phép.

## Bất biến (Immutability)

- Ưu tiên DTO và value object bất biến cho dữ liệu đi qua ranh giới service.
- Dùng property `readonly` hoặc constructor bất biến cho payload request/response khi có thể.
- Giữ array cho các map đơn giản; nâng các cấu trúc quan trọng về nghiệp vụ lên thành class tường minh.

## Định dạng

- Dùng **PHP-CS-Fixer** hoặc **Laravel Pint** để format.
- Dùng **PHPStan** hoặc **Psalm** để phân tích tĩnh.
- Giữ các script Composer được commit sẵn để cùng một lệnh chạy được cả ở local lẫn trong CI.

## Import

- Thêm câu lệnh `use` cho mọi class, interface và trait được tham chiếu.
- Tránh dựa vào global namespace trừ khi dự án chủ ý ưu tiên tên đầy đủ (fully qualified name).

## Xử lý lỗi

- Throw exception cho các trạng thái ngoại lệ; tránh trả về `false`/`null` như một kênh lỗi ngầm trong code mới.
- Chuyển input từ framework/request thành DTO đã validate trước khi nó tới domain logic.

## Tham chiếu

Xem skill: `backend-patterns` để có hướng dẫn rộng hơn về phân tầng service/repository.
