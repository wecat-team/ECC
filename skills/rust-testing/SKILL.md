---
name: rust-testing
description: "Các pattern kiểm thử Rust gồm unit test, integration test, async testing, property-based testing, mocking và coverage. Tuân theo phương pháp TDD. Dùng khi viết test Rust — unit, integration, async, property-based hoặc coverage."
metadata:
  origin: ECC
---

# Pattern kiểm thử Rust

Các pattern kiểm thử Rust toàn diện để viết test đáng tin cậy, dễ bảo trì theo phương pháp TDD.

## Khi nào dùng

- Viết function, method hoặc trait Rust mới
- Bổ sung coverage cho code hiện có
- Tạo benchmark cho code quan trọng về hiệu năng
- Triển khai property-based test cho việc kiểm tra đầu vào (input validation)
- Tuân theo workflow TDD trong các dự án Rust

## Cách hoạt động

1. **Xác định code cần test** — Tìm function, trait hoặc module cần test
2. **Viết test** — Dùng `#[test]` trong module `#[cfg(test)]`, rstest cho parameterized test, hoặc proptest cho property-based test
3. **Mock dependency** — Dùng mockall để cô lập đơn vị đang được test
4. **Chạy test (RED)** — Xác nhận test fail với đúng lỗi mong đợi
5. **Triển khai (GREEN)** — Viết code tối thiểu để pass
6. **Refactor** — Cải thiện code trong khi giữ test xanh
7. **Kiểm tra coverage** — Dùng cargo-llvm-cov, mục tiêu 80%+

## Workflow TDD cho Rust

### Chu trình RED-GREEN-REFACTOR

```
RED     → Write a failing test first
GREEN   → Write minimal code to pass the test
REFACTOR → Improve code while keeping tests green
REPEAT  → Continue with next requirement
```

### TDD từng bước trong Rust

```rust
// RED: Write test first, use todo!() as placeholder
pub fn add(a: i32, b: i32) -> i32 { todo!() }

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn test_add() { assert_eq!(add(2, 3), 5); }
}
// cargo test → panics at 'not yet implemented'
```

```rust
// GREEN: Replace todo!() with minimal implementation
pub fn add(a: i32, b: i32) -> i32 { a + b }
// cargo test → PASS, then REFACTOR while keeping tests green
```

## Unit Test

### Tổ chức test ở cấp module

```rust
// src/user.rs
pub struct User {
    pub name: String,
    pub email: String,
}

impl User {
    pub fn new(name: impl Into<String>, email: impl Into<String>) -> Result<Self, String> {
        let email = email.into();
        if !email.contains('@') {
            return Err(format!("invalid email: {email}"));
        }
        Ok(Self { name: name.into(), email })
    }

    pub fn display_name(&self) -> &str {
        &self.name
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn creates_user_with_valid_email() {
        let user = User::new("Alice", "alice@example.com").unwrap();
        assert_eq!(user.display_name(), "Alice");
        assert_eq!(user.email, "alice@example.com");
    }

    #[test]
    fn rejects_invalid_email() {
        let result = User::new("Bob", "not-an-email");
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("invalid email"));
    }
}
```

### Macro assertion

```rust
assert_eq!(2 + 2, 4);                                    // Equality
assert_ne!(2 + 2, 5);                                    // Inequality
assert!(vec![1, 2, 3].contains(&2));                     // Boolean
assert_eq!(value, 42, "expected 42 but got {value}");    // Custom message
assert!((0.1_f64 + 0.2 - 0.3).abs() < f64::EPSILON);   // Float comparison
```

## Test lỗi và panic

### Test giá trị trả về `Result`

```rust
#[test]
fn parse_returns_error_for_invalid_input() {
    let result = parse_config("}{invalid");
    assert!(result.is_err());

    // Assert specific error variant
    let err = result.unwrap_err();
    assert!(matches!(err, ConfigError::ParseError(_)));
}

#[test]
fn parse_succeeds_for_valid_input() -> Result<(), Box<dyn std::error::Error>> {
    let config = parse_config(r#"{"port": 8080}"#)?;
    assert_eq!(config.port, 8080);
    Ok(()) // Test fails if any ? returns Err
}
```

### Test panic

```rust
#[test]
#[should_panic]
fn panics_on_empty_input() {
    process(&[]);
}

#[test]
#[should_panic(expected = "index out of bounds")]
fn panics_with_specific_message() {
    let v: Vec<i32> = vec![];
    let _ = v[0];
}
```

## Integration Test

### Cấu trúc file

```text
my_crate/
├── src/
│   └── lib.rs
├── tests/              # Integration tests
│   ├── api_test.rs     # Each file is a separate test binary
│   ├── db_test.rs
│   └── common/         # Shared test utilities
│       └── mod.rs
```

### Viết Integration Test

```rust
// tests/api_test.rs
use my_crate::{App, Config};

#[test]
fn full_request_lifecycle() {
    let config = Config::test_default();
    let app = App::new(config);

    let response = app.handle_request("/health");
    assert_eq!(response.status, 200);
    assert_eq!(response.body, "OK");
}
```

## Async Test

### Với Tokio

```rust
#[tokio::test]
async fn fetches_data_successfully() {
    let client = TestClient::new().await;
    let result = client.get("/data").await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().items.len(), 3);
}

#[tokio::test]
async fn handles_timeout() {
    use std::time::Duration;
    let result = tokio::time::timeout(
        Duration::from_millis(100),
        slow_operation(),
    ).await;

    assert!(result.is_err(), "should have timed out");
}
```

## Pattern tổ chức test

### Parameterized Test với `rstest`

```rust
use rstest::{rstest, fixture};

#[rstest]
#[case("hello", 5)]
#[case("", 0)]
#[case("rust", 4)]
fn test_string_length(#[case] input: &str, #[case] expected: usize) {
    assert_eq!(input.len(), expected);
}

// Fixtures
#[fixture]
fn test_db() -> TestDb {
    TestDb::new_in_memory()
}

#[rstest]
fn test_insert(test_db: TestDb) {
    test_db.insert("key", "value");
    assert_eq!(test_db.get("key"), Some("value".into()));
}
```

### Test Helper

```rust
#[cfg(test)]
mod tests {
    use super::*;

    /// Creates a test user with sensible defaults.
    fn make_user(name: &str) -> User {
        User::new(name, &format!("{name}@test.com")).unwrap()
    }

    #[test]
    fn user_display() {
        let user = make_user("alice");
        assert_eq!(user.display_name(), "alice");
    }
}
```

## Property-Based Testing với `proptest`

### Property Test cơ bản

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn encode_decode_roundtrip(input in ".*") {
        let encoded = encode(&input);
        let decoded = decode(&encoded).unwrap();
        assert_eq!(input, decoded);
    }

    #[test]
    fn sort_preserves_length(mut vec in prop::collection::vec(any::<i32>(), 0..100)) {
        let original_len = vec.len();
        vec.sort();
        assert_eq!(vec.len(), original_len);
    }

    #[test]
    fn sort_produces_ordered_output(mut vec in prop::collection::vec(any::<i32>(), 0..100)) {
        vec.sort();
        for window in vec.windows(2) {
            assert!(window[0] <= window[1]);
        }
    }
}
```

### Strategy tùy chỉnh

```rust
use proptest::prelude::*;

fn valid_email() -> impl Strategy<Value = String> {
    ("[a-z]{1,10}", "[a-z]{1,5}")
        .prop_map(|(user, domain)| format!("{user}@{domain}.com"))
}

proptest! {
    #[test]
    fn accepts_valid_emails(email in valid_email()) {
        assert!(User::new("Test", &email).is_ok());
    }
}
```

## Mocking với `mockall`

### Mocking dựa trên Trait

```rust
use mockall::{automock, predicate::eq};

#[automock]
trait UserRepository {
    fn find_by_id(&self, id: u64) -> Option<User>;
    fn save(&self, user: &User) -> Result<(), StorageError>;
}

#[test]
fn service_returns_user_when_found() {
    let mut mock = MockUserRepository::new();
    mock.expect_find_by_id()
        .with(eq(42))
        .times(1)
        .returning(|_| Some(User { id: 42, name: "Alice".into() }));

    let service = UserService::new(Box::new(mock));
    let user = service.get_user(42).unwrap();
    assert_eq!(user.name, "Alice");
}

#[test]
fn service_returns_none_when_not_found() {
    let mut mock = MockUserRepository::new();
    mock.expect_find_by_id()
        .returning(|_| None);

    let service = UserService::new(Box::new(mock));
    assert!(service.get_user(99).is_none());
}
```

## Doc Test

### Tài liệu có thể thực thi

```rust
/// Adds two numbers together.
///
/// # Examples
///
/// ```
/// use my_crate::add;
///
/// assert_eq!(add(2, 3), 5);
/// assert_eq!(add(-1, 1), 0);
/// ```
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

/// Parses a config string.
///
/// # Errors
///
/// Returns `Err` if the input is not valid TOML.
///
/// ```no_run
/// use my_crate::parse_config;
///
/// let config = parse_config(r#"port = 8080"#).unwrap();
/// assert_eq!(config.port, 8080);
/// ```
///
/// ```no_run
/// use my_crate::parse_config;
///
/// assert!(parse_config("}{invalid").is_err());
/// ```
pub fn parse_config(input: &str) -> Result<Config, ParseError> {
    todo!()
}
```

## Benchmark với Criterion

```toml
# Cargo.toml
[dev-dependencies]
criterion = { version = "0.5", features = ["html_reports"] }

[[bench]]
name = "benchmark"
harness = false
```

```rust
// benches/benchmark.rs
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn fibonacci(n: u64) -> u64 {
    match n {
        0 | 1 => n,
        _ => fibonacci(n - 1) + fibonacci(n - 2),
    }
}

fn bench_fibonacci(c: &mut Criterion) {
    c.bench_function("fib 20", |b| b.iter(|| fibonacci(black_box(20))));
}

criterion_group!(benches, bench_fibonacci);
criterion_main!(benches);
```

## Coverage của test

### Chạy Coverage

```bash
# Install: cargo install cargo-llvm-cov (or use taiki-e/install-action in CI)
cargo llvm-cov                    # Summary
cargo llvm-cov --html             # HTML report
cargo llvm-cov --lcov > lcov.info # LCOV format for CI
cargo llvm-cov --fail-under-lines 80  # Fail if below threshold
```

### Mục tiêu Coverage

| Loại code | Mục tiêu |
|-----------|--------|
| Business logic quan trọng | 100% |
| API công khai | 90%+ |
| Code thông thường | 80%+ |
| Code sinh tự động / FFI binding | Loại trừ |

## Lệnh test

```bash
cargo test                        # Run all tests
cargo test -- --nocapture         # Show println output
cargo test test_name              # Run tests matching pattern
cargo test --lib                  # Unit tests only
cargo test --test api_test        # Integration tests only
cargo test --doc                  # Doc tests only
cargo test --no-fail-fast         # Don't stop on first failure
cargo test -- --ignored           # Run ignored tests
```

## Best Practice

**NÊN:**
- Viết test TRƯỚC (TDD)
- Dùng module `#[cfg(test)]` cho unit test
- Test hành vi, không test chi tiết triển khai
- Dùng tên test mang tính mô tả, giải thích rõ kịch bản
- Ưu tiên `assert_eq!` hơn `assert!` để có thông báo lỗi tốt hơn
- Dùng `?` trong test trả về `Result` để đầu ra lỗi gọn hơn
- Giữ các test độc lập — không dùng mutable state chung

**KHÔNG NÊN:**
- Dùng `#[should_panic]` khi có thể test `Result::is_err()` thay thế
- Mock mọi thứ — ưu tiên integration test khi khả thi
- Bỏ qua flaky test — hãy sửa hoặc cách ly (quarantine) chúng
- Dùng `sleep()` trong test — hãy dùng channel, barrier hoặc `tokio::time::pause()`
- Bỏ qua việc test nhánh lỗi

## Tích hợp CI

```yaml
# GitHub Actions
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: dtolnay/rust-toolchain@stable
      with:
        components: clippy, rustfmt

    - name: Check formatting
      run: cargo fmt --check

    - name: Clippy
      run: cargo clippy -- -D warnings

    - name: Run tests
      run: cargo test

    - uses: taiki-e/install-action@cargo-llvm-cov

    - name: Coverage
      run: cargo llvm-cov --fail-under-lines 80
```

**Hãy nhớ**: Test chính là tài liệu. Chúng cho thấy code của bạn được dùng như thế nào. Hãy viết test rõ ràng và luôn cập nhật.
