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
# Hook cho C++

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung dành riêng cho C++.

## Build Hook

Chạy các kiểm tra sau trước khi commit thay đổi C++:

```bash
# Format check
clang-format --dry-run --Werror src/*.cpp src/*.hpp

# Static analysis
clang-tidy src/*.cpp -- -std=c++17

# Build
cmake --build build

# Tests
ctest --test-dir build --output-on-failure
```

## Pipeline CI được khuyến nghị

1. **clang-format** — kiểm tra định dạng
2. **clang-tidy** — phân tích tĩnh
3. **cppcheck** — phân tích bổ sung
4. **cmake build** — biên dịch
5. **ctest** — chạy test với sanitizer
