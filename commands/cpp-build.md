---
description: Sửa dần dần các lỗi build C++, vấn đề CMake và vấn đề linker. Gọi agent cpp-build-resolver để sửa tối thiểu, chính xác.
---

# Build và Fix C++

Lệnh này gọi agent **cpp-build-resolver** để sửa dần dần các lỗi build C++ bằng những thay đổi tối thiểu.

## Lệnh này làm gì

1. **Chạy chẩn đoán**: Thực thi `cmake --build`, `clang-tidy`, `cppcheck`
2. **Phân tích lỗi**: Nhóm theo file và sắp xếp theo mức độ nghiêm trọng
3. **Sửa dần dần**: Mỗi lần một lỗi
4. **Xác minh từng bản sửa**: Chạy lại build sau mỗi thay đổi
5. **Báo cáo tóm tắt**: Hiển thị những gì đã sửa và những gì còn lại

## Khi nào dùng

Dùng `/cpp-build` khi:
- `cmake --build build` thất bại với lỗi
- Lỗi linker (undefined reference, multiple definition)
- Lỗi template instantiation
- Vấn đề include/dependency
- Sau khi pull các thay đổi làm hỏng build

## Các lệnh chẩn đoán được chạy

```bash
# CMake configure
cmake -B build -S .

# Build
cmake --build build 2>&1 | head -100

# Static analysis (if available)
clang-tidy src/*.cpp -- -std=c++17
cppcheck --enable=all src/
```

## Ví dụ một phiên làm việc

```text
User: /cpp-build

Agent:
# C++ Build Resolution

## Initial Diagnostics

```bash
$ cmake --build build
src/service/user.cpp:25:15: error: use of undeclared identifier 'UserRepository'
src/handler/api.cpp:42:9: error: no matching function for call to 'process'
src/handler/api.cpp:58:1: error: non-void function does not return a value
```

Errors found: 3

## Fix 1: Undeclared Identifier

File: src/service/user.cpp:25
Error: use of undeclared identifier 'UserRepository'
Cause: Missing include

```cpp
// Added include
#include "repository/user_repository.hpp"
```

```bash
$ cmake --build build
# 2 errors remaining
```

## Fix 2: No Matching Function

File: src/handler/api.cpp:42
Error: no matching function for call to 'process'

```cpp
// Changed
process(params.get("count"));
// To
process(std::stoi(params.get("count")));
```

```bash
$ cmake --build build
# 1 error remaining
```

## Fix 3: Missing Return

File: src/handler/api.cpp:58
Error: non-void function does not return a value

```cpp
std::optional<User> getUser(const std::string& id) {
    if (id.empty()) {
        return std::nullopt;
    }
    auto user = findUser(id);
    // Added missing return
    return user;
}
```

```bash
$ cmake --build build
# Build successful!
```

## Final Verification

```bash
$ ctest --test-dir build --output-on-failure
Test project build
    1/5 Test #1: unit_tests ........   Passed    0.02 sec
    2/5 Test #2: integration_tests    Passed    0.15 sec
All tests passed.
```

## Summary

| Metric | Count |
|--------|-------|
| Build errors fixed | 3 |
| Linker errors fixed | 0 |
| Files modified | 2 |
| Remaining issues | 0 |

Build Status: PASS: SUCCESS
```

## Các lỗi phổ biến đã được sửa

| Lỗi | Cách sửa điển hình |
|-------|-------------|
| `undeclared identifier` | Thêm `#include` hoặc sửa lỗi gõ sai |
| `no matching function` | Sửa type của đối số hoặc thêm overload |
| `undefined reference` | Link thư viện hoặc thêm phần implementation |
| `multiple definition` | Dùng `inline` hoặc chuyển sang .cpp |
| `incomplete type` | Thay forward declaration bằng `#include` |
| `no member named X` | Sửa tên member hoặc include |
| `cannot convert X to Y` | Thêm ép kiểu phù hợp |
| `CMake Error` | Sửa cấu hình CMakeLists.txt |

## Chiến lược sửa lỗi

1. **Lỗi biên dịch trước** - Code phải compile được
2. **Lỗi linker thứ hai** - Giải quyết các undefined reference
3. **Cảnh báo thứ ba** - Sửa với `-Wall -Wextra`
4. **Mỗi lần một bản sửa** - Xác minh từng thay đổi
5. **Thay đổi tối thiểu** - Không refactor, chỉ sửa lỗi

## Điều kiện dừng

Agent sẽ dừng và báo cáo nếu:
- Cùng một lỗi vẫn còn sau 3 lần thử
- Cách sửa gây ra nhiều lỗi hơn
- Đòi hỏi thay đổi kiến trúc
- Thiếu dependency bên ngoài

## Lệnh liên quan

- `/cpp-test` - Chạy test sau khi build thành công
- `/cpp-review` - Review chất lượng code
- skill `verification-loop` - Vòng xác minh đầy đủ

## Liên quan

- Agent: `agents/cpp-build-resolver.md`
- Skill: `skills/cpp-coding-standards/`
