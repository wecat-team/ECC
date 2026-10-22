---
paths:
  - "**/*.cpp"
  - "**/*.hpp"
  - "**/*.cc"
  - "**/*.hh"
  - "**/*.cxx"
  - "**/*.h"
  - "**/CMakeLists.txt"
---
# Phong cách code C++

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung dành riêng cho C++.

## C++ hiện đại (C++17/20/23)

- Ưu tiên **tính năng C++ hiện đại** hơn các cấu trúc kiểu C
- Dùng `auto` khi kiểu đã rõ ràng từ ngữ cảnh
- Dùng `constexpr` cho hằng số compile-time
- Dùng structured binding: `auto [key, value] = map_entry;`

## Quản lý tài nguyên

- **RAII ở mọi nơi** — không dùng `new`/`delete` thủ công
- Dùng `std::unique_ptr` cho quyền sở hữu độc quyền
- Chỉ dùng `std::shared_ptr` khi thực sự cần quyền sở hữu chia sẻ
- Dùng `std::make_unique` / `std::make_shared` thay cho `new` thuần

## Quy ước đặt tên

- Type/Class: `PascalCase`
- Hàm/Method: `snake_case` hoặc `camelCase` (theo quy ước của dự án)
- Hằng số: `kPascalCase` hoặc `UPPER_SNAKE_CASE`
- Namespace: `lowercase`
- Biến thành viên: `snake_case_` (có dấu gạch dưới ở cuối) hoặc tiền tố `m_`

## Định dạng

- Dùng **clang-format** — không tranh cãi về style
- Chạy `clang-format -i <file>` trước khi commit

## Tham chiếu

Xem skill: `cpp-coding-standards` để có các tiêu chuẩn và hướng dẫn code C++ toàn diện.
