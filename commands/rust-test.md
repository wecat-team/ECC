---
description: Áp dụng quy trình TDD cho Rust. Viết test trước, sau đó triển khai. Xác minh coverage 80%+ với cargo-llvm-cov.
---

# Lệnh Rust TDD

Lệnh này áp dụng phương pháp phát triển hướng kiểm thử (TDD) cho code Rust bằng `#[test]`, rstest, proptest và mockall.

## Lệnh này làm gì

1. **Định nghĩa Type/Trait**: Dựng khung signature của function với `todo!()`
2. **Viết test**: Tạo module test toàn diện (RED)
3. **Chạy test**: Xác minh test thất bại đúng lý do
4. **Triển khai code**: Viết code tối thiểu để pass (GREEN)
5. **Refactor**: Cải thiện trong khi giữ test xanh
6. **Kiểm tra coverage**: Đảm bảo coverage 80%+ với cargo-llvm-cov

## Khi nào dùng

Dùng `/rust-test` khi:
- Triển khai function, method hoặc trait Rust mới
- Bổ sung test coverage cho code Rust hiện có
- Sửa bug (viết test thất bại trước)
- Xây dựng logic nghiệp vụ quan trọng
- Học quy trình TDD trong Rust

## Chu trình TDD

```
RED     -> Write failing test first
GREEN   -> Implement minimal code to pass
REFACTOR -> Improve code, tests stay green
REPEAT  -> Next test case
```

## Ví dụ phiên làm việc

````text
User: /rust-test I need a function to validate user registration

Agent:
# TDD Session: Registration Validator

## Step 1: Define Interface

```rust
// src/validator.rs
pub struct RegistrationRequest {
    pub name: String,
    pub email: String,
    pub password: String,
}

pub enum ValidationResult {
    Valid,
    Invalid(Vec<String>),
}

pub fn validate_registration(request: &RegistrationRequest) -> ValidationResult {
    todo!()
}
```

## Step 2: Write Tests (RED)

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn valid_registration_returns_valid() {
        let request = RegistrationRequest {
            name: "Alice".into(),
            email: "alice@example.com".into(),
            password: "SecureP@ss1".into(),
        };
        assert!(matches!(validate_registration(&request), ValidationResult::Valid));
    }

    #[test]
    fn blank_name_returns_invalid() {
        let request = RegistrationRequest {
            name: "".into(),
            email: "alice@example.com".into(),
            password: "SecureP@ss1".into(),
        };
        match validate_registration(&request) {
            ValidationResult::Invalid(errors) => {
                assert!(errors.contains(&"Name is required".to_string()));
            }
            ValidationResult::Valid => panic!("expected Invalid"),
        }
    }

    #[test]
    fn invalid_email_returns_invalid() {
        let request = RegistrationRequest {
            name: "Alice".into(),
            email: "not-an-email".into(),
            password: "SecureP@ss1".into(),
        };
        assert!(matches!(
            validate_registration(&request),
            ValidationResult::Invalid(_)
        ));
    }

    #[test]
    fn short_password_returns_invalid() {
        let request = RegistrationRequest {
            name: "Alice".into(),
            email: "alice@example.com".into(),
            password: "short".into(),
        };
        assert!(matches!(
            validate_registration(&request),
            ValidationResult::Invalid(_)
        ));
    }
}
```

## Step 3: Run Tests — Verify FAIL

```bash
$ cargo test
running 4 tests
test tests::valid_registration_returns_valid ... FAILED (not yet implemented)
test tests::blank_name_returns_invalid ... FAILED
test tests::invalid_email_returns_invalid ... FAILED
test tests::short_password_returns_invalid ... FAILED
```

Tests fail as expected (todo! panic).

## Step 4: Implement Minimal Code (GREEN)

```rust
pub fn validate_registration(request: &RegistrationRequest) -> ValidationResult {
    let mut errors = Vec::new();

    if request.name.trim().is_empty() {
        errors.push("Name is required".into());
    }
    if !request.email.contains('@') {
        errors.push("Invalid email format".into());
    }
    if request.password.len() < 8 {
        errors.push("Password must be at least 8 characters".into());
    }

    if errors.is_empty() {
        ValidationResult::Valid
    } else {
        ValidationResult::Invalid(errors)
    }
}
```

## Step 5: Run Tests — Verify PASS

```bash
$ cargo test
running 4 tests
test tests::valid_registration_returns_valid ... ok
test tests::blank_name_returns_invalid ... ok
test tests::invalid_email_returns_invalid ... ok
test tests::short_password_returns_invalid ... ok

test result: ok. 4 passed; 0 failed
```

All tests passing!

## Step 6: Check Coverage

```bash
$ cargo llvm-cov
Coverage: 100.0% of lines
```

Coverage: 100%

## TDD Complete!
````

## Các pattern test

### Unit Test

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn adds_two_numbers() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    fn handles_error() -> Result<(), Box<dyn std::error::Error>> {
        let result = parse_config(r#"port = 8080"#)?;
        assert_eq!(result.port, 8080);
        Ok(())
    }
}
```

### Test tham số hóa với rstest

```rust
use rstest::{rstest, fixture};

#[rstest]
#[case("hello", 5)]
#[case("", 0)]
#[case("rust", 4)]
fn test_string_length(#[case] input: &str, #[case] expected: usize) {
    assert_eq!(input.len(), expected);
}
```

### Test bất đồng bộ

```rust
#[tokio::test]
async fn fetches_data_successfully() {
    let client = TestClient::new().await;
    let result = client.get("/data").await;
    assert!(result.is_ok());
}
```

### Test dựa trên thuộc tính (Property-Based)

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn encode_decode_roundtrip(input in ".*") {
        let encoded = encode(&input);
        let decoded = decode(&encoded).unwrap();
        assert_eq!(input, decoded);
    }
}
```

## Các lệnh coverage

```bash
# Summary report
cargo llvm-cov

# HTML report
cargo llvm-cov --html

# Fail if below threshold
cargo llvm-cov --fail-under-lines 80

# Run specific test
cargo test test_name

# Run with output
cargo test -- --nocapture

# Run without stopping on first failure
cargo test --no-fail-fast
```

## Mục tiêu coverage

| Loại code | Mục tiêu |
|-----------|--------|
| Logic nghiệp vụ quan trọng | 100% |
| API public | 90%+ |
| Code chung | 80%+ |
| Binding sinh tự động / FFI | Loại trừ |

## Best practice của TDD

**NÊN:**
- Viết test TRƯỚC, trước bất kỳ phần triển khai nào
- Chạy test sau mỗi thay đổi
- Dùng `assert_eq!` thay vì `assert!` để có thông báo lỗi tốt hơn
- Dùng `?` trong các test trả về `Result` để output gọn hơn
- Test hành vi, không phải phần triển khai
- Bao gồm edge case (rỗng, biên, đường lỗi)

**KHÔNG NÊN:**
- Viết phần triển khai trước test
- Bỏ qua pha RED
- Dùng `#[should_panic]` khi `Result::is_err()` đủ dùng
- Dùng `sleep()` trong test — hãy dùng channel hoặc `tokio::time::pause()`
- Mock mọi thứ — ưu tiên integration test khi khả thi

## Các lệnh liên quan

- `/rust-build` - Sửa lỗi build
- `/rust-review` - Review code sau khi triển khai
- skill `verification-loop` - Chạy vòng lặp verification đầy đủ

## Liên quan

- Skill: `skills/rust-testing/`
- Skill: `skills/rust-patterns/`
