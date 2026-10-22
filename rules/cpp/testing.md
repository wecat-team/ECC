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
# Kiểm thử C++

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung dành riêng cho C++.

## Framework

Dùng **GoogleTest** (gtest/gmock) với **CMake/CTest**.

## Chạy test

```bash
cmake --build build && ctest --test-dir build --output-on-failure
```

## Coverage

```bash
cmake -DCMAKE_CXX_FLAGS="--coverage" -DCMAKE_EXE_LINKER_FLAGS="--coverage" ..
cmake --build .
ctest --output-on-failure
lcov --capture --directory . --output-file coverage.info
```

## Sanitizer

Luôn chạy test với sanitizer trong CI:

```bash
cmake -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined" ..
```

## Tham chiếu

Xem skill: `cpp-testing` để có các pattern kiểm thử C++ chi tiết, quy trình TDD và cách dùng GoogleTest/GMock.
