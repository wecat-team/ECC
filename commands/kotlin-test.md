---
description: Áp dụng quy trình TDD cho Kotlin. Viết test Kotest trước, rồi mới triển khai. Xác minh coverage 80%+ bằng Kover.
---

# Lệnh Kotlin TDD

Command này áp dụng phương pháp phát triển hướng kiểm thử (TDD) cho code Kotlin, sử dụng Kotest, MockK và Kover.

## Command này làm gì

1. **Định nghĩa Type/Interface**: Dựng sườn chữ ký hàm trước
2. **Viết test Kotest**: Tạo các test spec toàn diện (RED)
3. **Chạy test**: Xác minh test thất bại đúng lý do
4. **Triển khai code**: Viết code tối thiểu để pass (GREEN)
5. **Refactor**: Cải thiện trong khi giữ test xanh
6. **Kiểm tra coverage**: Đảm bảo coverage từ 80% trở lên với Kover

## Khi nào dùng

Dùng `/kotlin-test` khi:
- Triển khai các hàm hoặc class Kotlin mới
- Bổ sung test coverage cho code Kotlin hiện có
- Sửa bug (viết test thất bại trước)
- Xây dựng business logic quan trọng
- Học quy trình TDD trong Kotlin

## Chu trình TDD

```
RED     -> Write failing Kotest test
GREEN   -> Implement minimal code to pass
REFACTOR -> Improve code, tests stay green
REPEAT  -> Next test case
```

## Phiên làm việc ví dụ

````text
User: /kotlin-test I need a function to validate user registration requests

Agent:
# TDD Session: Registration Validator

## Step 1: Define Interface

```kotlin
// validator/RegistrationValidator.kt
package com.example.validator

data class RegistrationRequest(
    val name: String,
    val email: String,
    val password: String,
)

sealed class ValidationResult {
    data object Valid : ValidationResult()
    data class Invalid(val errors: List<String>) : ValidationResult()
}

fun validateRegistration(request: RegistrationRequest): ValidationResult {
    TODO("not implemented")
}
```

## Step 2: Write Kotest Tests (RED)

```kotlin
// validator/RegistrationValidatorTest.kt
package com.example.validator

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

class RegistrationValidatorTest : FunSpec({
    test("valid registration returns Valid") {
        val request = RegistrationRequest(
            name = "Alice",
            email = "alice@example.com",
            password = "SecureP@ss1",
        )

        val result = validateRegistration(request)

        result.shouldBeInstanceOf<ValidationResult.Valid>()
    }

    test("blank name returns Invalid") {
        val request = RegistrationRequest(
            name = "",
            email = "alice@example.com",
            password = "SecureP@ss1",
        )

        val result = validateRegistration(request)

        val invalid = result.shouldBeInstanceOf<ValidationResult.Invalid>()
        invalid.errors shouldBe listOf("Name is required")
    }

    test("invalid email returns Invalid") {
        val request = RegistrationRequest(
            name = "Alice",
            email = "not-an-email",
            password = "SecureP@ss1",
        )

        val result = validateRegistration(request)

        val invalid = result.shouldBeInstanceOf<ValidationResult.Invalid>()
        invalid.errors shouldBe listOf("Invalid email format")
    }

    test("short password returns Invalid") {
        val request = RegistrationRequest(
            name = "Alice",
            email = "alice@example.com",
            password = "short",
        )

        val result = validateRegistration(request)

        val invalid = result.shouldBeInstanceOf<ValidationResult.Invalid>()
        invalid.errors shouldBe listOf("Password must be at least 8 characters")
    }

    test("multiple errors returns all errors") {
        val request = RegistrationRequest(
            name = "",
            email = "bad",
            password = "short",
        )

        val result = validateRegistration(request)

        val invalid = result.shouldBeInstanceOf<ValidationResult.Invalid>()
        invalid.errors.size shouldBe 3
    }
})
```

## Step 3: Run Tests - Verify FAIL

```bash
$ ./gradlew test

RegistrationValidatorTest > valid registration returns Valid FAILED
  kotlin.NotImplementedError: An operation is not implemented

FAILED (5 tests, 0 passed, 5 failed)
```

✓ Tests fail as expected (NotImplementedError).

## Step 4: Implement Minimal Code (GREEN)

```kotlin
// validator/RegistrationValidator.kt
package com.example.validator

private val EMAIL_REGEX = Regex("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
private const val MIN_PASSWORD_LENGTH = 8

fun validateRegistration(request: RegistrationRequest): ValidationResult {
    val errors = buildList {
        if (request.name.isBlank()) add("Name is required")
        if (!EMAIL_REGEX.matches(request.email)) add("Invalid email format")
        if (request.password.length < MIN_PASSWORD_LENGTH) add("Password must be at least $MIN_PASSWORD_LENGTH characters")
    }

    return if (errors.isEmpty()) ValidationResult.Valid
    else ValidationResult.Invalid(errors)
}
```

## Step 5: Run Tests - Verify PASS

```bash
$ ./gradlew test

RegistrationValidatorTest > valid registration returns Valid PASSED
RegistrationValidatorTest > blank name returns Invalid PASSED
RegistrationValidatorTest > invalid email returns Invalid PASSED
RegistrationValidatorTest > short password returns Invalid PASSED
RegistrationValidatorTest > multiple errors returns all errors PASSED

PASSED (5 tests, 5 passed, 0 failed)
```

✓ All tests passing!

## Step 6: Check Coverage

```bash
$ ./gradlew koverHtmlReport

Coverage: 100.0% of statements
```

✓ Coverage: 100%

## TDD Complete!
````

## Các pattern test

### StringSpec (đơn giản nhất)

```kotlin
class CalculatorTest : StringSpec({
    "add two positive numbers" {
        Calculator.add(2, 3) shouldBe 5
    }
})
```

### BehaviorSpec (BDD)

```kotlin
class OrderServiceTest : BehaviorSpec({
    Given("a valid order") {
        When("placed") {
            Then("should be confirmed") { /* ... */ }
        }
    }
})
```

### Data-Driven Test

```kotlin
class ParserTest : FunSpec({
    context("valid inputs") {
        withData("2026-01-15", "2026-12-31", "2000-01-01") { input ->
            parseDate(input).shouldNotBeNull()
        }
    }
})
```

### Test Coroutine

```kotlin
class AsyncServiceTest : FunSpec({
    test("concurrent fetch completes") {
        runTest {
            val result = service.fetchAll()
            result.shouldNotBeEmpty()
        }
    }
})
```

## Các lệnh coverage

```bash
# Run tests with coverage
./gradlew koverHtmlReport

# Verify coverage thresholds
./gradlew koverVerify

# XML report for CI
./gradlew koverXmlReport

# Open HTML report
open build/reports/kover/html/index.html

# Run specific test class
./gradlew test --tests "com.example.UserServiceTest"

# Run with verbose output
./gradlew test --info
```

## Mục tiêu coverage

| Loại code | Mục tiêu |
|-----------|--------|
| Business logic quan trọng | 100% |
| API công khai | 90%+ |
| Code thông thường | 80%+ |
| Code được sinh tự động | Loại trừ |

## Best practice của TDD

**NÊN:**
- Viết test TRƯỚC, trước bất kỳ phần triển khai nào
- Chạy test sau mỗi thay đổi
- Dùng matcher của Kotest để có assertion giàu biểu đạt
- Dùng `coEvery`/`coVerify` của MockK cho các suspend function
- Test hành vi, không test chi tiết triển khai
- Bao gồm các edge case (rỗng, null, giá trị tối đa)

**KHÔNG NÊN:**
- Viết phần triển khai trước test
- Bỏ qua pha RED
- Test trực tiếp các hàm private
- Dùng `Thread.sleep()` trong test coroutine
- Bỏ qua các flaky test

## Các command liên quan

- `/kotlin-build` - Sửa lỗi build
- `/kotlin-review` - Review code sau khi triển khai
- skill `verification-loop` - Chạy vòng lặp xác minh đầy đủ

## Liên quan

- Skill: `skills/kotlin-testing/`
- Skill: `skills/tdd-workflow/`
