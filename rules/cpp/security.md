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
# Bảo mật C++

> File này mở rộng [common/security.md](../common/security.md) với nội dung dành riêng cho C++.

## An toàn bộ nhớ

- KHÔNG BAO GIỜ dùng `new`/`delete` thuần — dùng smart pointer
- KHÔNG BAO GIỜ dùng mảng kiểu C — dùng `std::array` hoặc `std::vector`
- KHÔNG BAO GIỜ dùng `malloc`/`free` — dùng cấp phát của C++
- Tránh `reinterpret_cast` trừ khi thực sự cần thiết

## Buffer Overflow

- Dùng `std::string` thay cho `char*`
- Dùng `.at()` để truy cập có kiểm tra giới hạn khi an toàn là ưu tiên
- KHÔNG BAO GIỜ dùng `strcpy`, `strcat`, `sprintf` — dùng `std::string` hoặc `fmt::format`

## Undefined Behavior

- Luôn khởi tạo biến
- Tránh tràn số nguyên có dấu (signed integer overflow)
- KHÔNG BAO GIỜ dereference con trỏ null hoặc dangling
- Dùng sanitizer trong CI:
  ```bash
  cmake -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined" ..
  ```

## Phân tích tĩnh

- Dùng **clang-tidy** cho các kiểm tra tự động:
  ```bash
  clang-tidy --checks='*' src/*.cpp
  ```
- Dùng **cppcheck** cho phân tích bổ sung:
  ```bash
  cppcheck --enable=all src/
  ```

## Tham chiếu

Xem skill: `cpp-coding-standards` để có hướng dẫn bảo mật chi tiết.
