---
description: Thực thi workflow TDD cho C++. Viết test GoogleTest trước, rồi mới triển khai. Xác minh coverage bằng gcov/lcov.
---

# Lệnh TDD C++

Lệnh này thực thi phương pháp test-driven development cho code C++ bằng GoogleTest/GoogleMock với CMake/CTest.

## Lệnh này làm gì

1. **Định nghĩa interface**: Dựng sườn chữ ký class/function trước
2. **Viết test**: Tạo các test case GoogleTest toàn diện (RED)
3. **Chạy test**: Xác minh test thất bại vì đúng lý do
4. **Triển khai code**: Viết code tối thiểu để pass (GREEN)
5. **Refactor**: Cải thiện trong khi giữ test xanh
6. **Kiểm tra coverage**: Đảm bảo coverage từ 80% trở lên

## Khi nào dùng

Dùng `/cpp-test` khi:
- Triển khai function hoặc class C++ mới
- Bổ sung test coverage cho code hiện có
- Sửa bug (viết test thất bại trước)
- Xây dựng business logic quan trọng
- Học workflow TDD trong C++

## Chu trình TDD

```
RED     → Write failing GoogleTest test
GREEN   → Implement minimal code to pass
REFACTOR → Improve code, tests stay green
REPEAT  → Next test case
```

## Ví dụ một phiên làm việc

````
User: /cpp-test I need a function to validate email addresses

Agent:
# TDD Session: Email Validator

## Step 1: Define Interface

```cpp
// validator/email.hpp
#pragma once
#include <string>
#include <expected>

enum class EmailError {
    Empty,
    InvalidFormat
};

std::expected<void, EmailError> validate_email(const std::string& email);
```

## Step 2: Write Tests (RED)

```cpp
// validator/email_test.cpp
#include <gtest/gtest.h>
#include "email.hpp"

TEST(ValidateEmail, AcceptsSimpleEmail) {
    auto result = validate_email("user@example.com");
    EXPECT_TRUE(result.has_value());
}

TEST(ValidateEmail, AcceptsSubdomain) {
    EXPECT_TRUE(validate_email("user@mail.example.com").has_value());
}

TEST(ValidateEmail, AcceptsPlus) {
    EXPECT_TRUE(validate_email("user+tag@example.com").has_value());
}

TEST(ValidateEmail, RejectsEmpty) {
    auto result = validate_email("");
    ASSERT_FALSE(result.has_value());
    EXPECT_EQ(result.error(), EmailError::Empty);
}

TEST(ValidateEmail, RejectsNoAtSign) {
    EXPECT_FALSE(validate_email("userexample.com").has_value());
}

TEST(ValidateEmail, RejectsNoDomain) {
    EXPECT_FALSE(validate_email("user@").has_value());
}

TEST(ValidateEmail, RejectsNoLocalPart) {
    EXPECT_FALSE(validate_email("@example.com").has_value());
}
```

## Step 3: Run Tests - Verify FAIL

```bash
$ cmake --build build && ctest --test-dir build --output-on-failure

1/1 Test #1: email_validator_test .....***Failed
    --- undefined reference to `validate_email`

FAIL
```

✓ Tests fail as expected (unimplemented).

## Step 4: Implement Minimal Code (GREEN)

```cpp
// validator/email.cpp
#include "email.hpp"
#include <regex>

std::expected<void, EmailError> validate_email(const std::string& email) {
    if (email.empty()) {
        return std::unexpected(EmailError::Empty);
    }
    static const std::regex pattern(R"([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})");
    if (!std::regex_match(email, pattern)) {
        return std::unexpected(EmailError::InvalidFormat);
    }
    return {};
}
```

## Step 5: Run Tests - Verify PASS

```bash
$ cmake --build build && ctest --test-dir build --output-on-failure

1/1 Test #1: email_validator_test .....   Passed    0.01 sec

100% tests passed.
```

✓ All tests passing!

## Step 6: Check Coverage

```bash
$ cmake -DCMAKE_CXX_FLAGS="--coverage" -B build && cmake --build build
$ ctest --test-dir build
$ lcov --capture --directory build --output-file coverage.info
$ lcov --list coverage.info

validator/email.cpp     | 100%
```

✓ Coverage: 100%

## TDD Complete!
````

## Các pattern test

### Test cơ bản
```cpp
TEST(SuiteName, TestName) {
    EXPECT_EQ(add(2, 3), 5);
    EXPECT_NE(result, nullptr);
    EXPECT_TRUE(is_valid);
    EXPECT_THROW(func(), std::invalid_argument);
}
```

### Fixture
```cpp
class DatabaseTest : public ::testing::Test {
protected:
    void SetUp() override { db_ = create_test_db(); }
    void TearDown() override { db_.reset(); }
    std::unique_ptr<Database> db_;
};

TEST_F(DatabaseTest, InsertsRecord) {
    db_->insert("key", "value");
    EXPECT_EQ(db_->get("key"), "value");
}
```

### Test tham số hóa (Parameterized)
```cpp
class PrimeTest : public ::testing::TestWithParam<std::pair<int, bool>> {};

TEST_P(PrimeTest, ChecksPrimality) {
    auto [input, expected] = GetParam();
    EXPECT_EQ(is_prime(input), expected);
}

INSTANTIATE_TEST_SUITE_P(Primes, PrimeTest, ::testing::Values(
    std::make_pair(2, true),
    std::make_pair(4, false),
    std::make_pair(7, true)
));
```

## Lệnh coverage

```bash
# Build with coverage
cmake -DCMAKE_CXX_FLAGS="--coverage" -DCMAKE_EXE_LINKER_FLAGS="--coverage" -B build

# Run tests
cmake --build build && ctest --test-dir build

# Generate coverage report
lcov --capture --directory build --output-file coverage.info
lcov --remove coverage.info '/usr/*' --output-file coverage.info
genhtml coverage.info --output-directory coverage_html
```

## Mục tiêu coverage

| Loại code | Mục tiêu |
|-----------|--------|
| Business logic quan trọng | 100% |
| Public APIs | 90%+ |
| Code thông thường | 80%+ |
| Code được sinh tự động | Loại trừ |

## Best practice TDD

**NÊN:**
- Viết test TRƯỚC, trước mọi phần implementation
- Chạy test sau mỗi thay đổi
- Dùng `EXPECT_*` (tiếp tục) thay vì `ASSERT_*` (dừng) khi phù hợp
- Test hành vi, không phải chi tiết triển khai
- Bao gồm edge case (rỗng, null, giá trị tối đa, điều kiện biên)

**KHÔNG NÊN:**
- Viết implementation trước test
- Bỏ qua pha RED
- Test trực tiếp các private method (hãy test qua public API)
- Dùng `sleep` trong test
- Bỏ qua các test flaky

## Lệnh liên quan

- `/cpp-build` - Sửa lỗi build
- `/cpp-review` - Review code sau khi triển khai
- skill `verification-loop` - Chạy vòng xác minh đầy đủ

## Liên quan

- Skill: `skills/cpp-testing/`
- Skill: `skills/tdd-workflow/`
