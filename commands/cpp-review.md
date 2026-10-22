---
description: Code review C++ toàn diện về an toàn bộ nhớ, idiom C++ hiện đại, đồng thời (concurrency) và bảo mật. Gọi agent cpp-reviewer.
---

# Code Review C++

Lệnh này gọi agent **cpp-reviewer** để code review toàn diện riêng cho C++.

## Lệnh này làm gì

1. **Xác định thay đổi C++**: Tìm các file `.cpp`, `.hpp`, `.cc`, `.h` đã sửa qua `git diff`
2. **Chạy phân tích tĩnh**: Thực thi `clang-tidy` và `cppcheck`
3. **Quét an toàn bộ nhớ**: Kiểm tra new/delete thô, buffer overflow, use-after-free
4. **Review đồng thời**: Phân tích thread safety, cách dùng mutex, data race
5. **Kiểm tra C++ hiện đại**: Xác minh code tuân theo quy ước và best practice của C++17/20
6. **Tạo báo cáo**: Phân loại issue theo mức độ nghiêm trọng

## Khi nào dùng

Dùng `/cpp-review` khi:
- Sau khi viết hoặc sửa code C++
- Trước khi commit các thay đổi C++
- Review pull request có code C++
- Làm quen với một codebase C++ mới
- Kiểm tra các vấn đề an toàn bộ nhớ

## Các hạng mục review

### CRITICAL (Phải sửa)
- `new`/`delete` thô không có RAII
- Buffer overflow và use-after-free
- Data race không có đồng bộ hóa
- Command injection qua `system()`
- Đọc biến chưa khởi tạo
- Dereference con trỏ null

### HIGH (Nên sửa)
- Vi phạm Rule of Five
- Thiếu `std::lock_guard` / `std::scoped_lock`
- Thread detached không quản lý lifetime đúng cách
- Ép kiểu kiểu C thay vì `static_cast`/`dynamic_cast`
- Thiếu `const` correctness

### MEDIUM (Cân nhắc)
- Copy không cần thiết (truyền theo giá trị thay vì `const&`)
- Thiếu `reserve()` trên container đã biết kích thước
- `using namespace std;` trong header
- Thiếu `[[nodiscard]]` trên các giá trị trả về quan trọng
- Template metaprogramming quá phức tạp

## Các kiểm tra tự động được chạy

```bash
# Static analysis
clang-tidy --checks='*,-llvmlibc-*' src/*.cpp -- -std=c++17

# Additional analysis
cppcheck --enable=all --suppress=missingIncludeSystem src/

# Build with warnings
cmake --build build -- -Wall -Wextra -Wpedantic
```

## Ví dụ sử dụng

```text
User: /cpp-review

Agent:
# C++ Code Review Report

## Files Reviewed
- src/handler/user.cpp (modified)
- src/service/auth.cpp (modified)

## Static Analysis Results
✓ clang-tidy: 2 warnings
✓ cppcheck: No issues

## Issues Found

[CRITICAL] Memory Leak
File: src/service/auth.cpp:45
Issue: Raw `new` without matching `delete`
```cpp
auto* session = new Session(userId);  // Memory leak!
cache[userId] = session;
```
Fix: Use `std::unique_ptr`
```cpp
auto session = std::make_unique<Session>(userId);
cache[userId] = std::move(session);
```

[HIGH] Missing const Reference
File: src/handler/user.cpp:28
Issue: Large object passed by value
```cpp
void processUser(User user) {  // Unnecessary copy
```
Fix: Pass by const reference
```cpp
void processUser(const User& user) {
```

## Summary
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 0

Recommendation: FAIL: Block merge until CRITICAL issue is fixed
```

## Tiêu chí phê duyệt

| Trạng thái | Điều kiện |
|--------|-----------|
| PASS: Approve | Không có issue CRITICAL hoặc HIGH |
| WARNING: Warning | Chỉ có issue MEDIUM (merge nhưng thận trọng) |
| FAIL: Block | Phát hiện issue CRITICAL hoặc HIGH |

## Tích hợp với các lệnh khác

- Dùng `/cpp-test` trước để đảm bảo test pass
- Dùng `/cpp-build` nếu có lỗi build
- Dùng `/cpp-review` trước khi commit
- Dùng `/code-review` cho các mối quan tâm không riêng của C++

## Liên quan

- Agent: `agents/cpp-reviewer.md`
- Skills: `skills/cpp-coding-standards/`, `skills/cpp-testing/`
