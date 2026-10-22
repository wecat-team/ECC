---
description: Sửa dần các lỗi build Rust, vấn đề borrow checker và vấn đề dependency. Gọi agent rust-build-resolver để sửa tối thiểu, chính xác.
---

# Rust Build and Fix

Lệnh này gọi agent **rust-build-resolver** để sửa dần các lỗi build Rust với thay đổi tối thiểu.

## Lệnh này làm gì

1. **Chạy chẩn đoán**: Thực thi `cargo check`, `cargo clippy`, `cargo fmt --check`
2. **Phân tích lỗi**: Xác định mã lỗi và các file bị ảnh hưởng
3. **Sửa dần**: Mỗi lần một lỗi
4. **Xác minh từng bản sửa**: Chạy lại `cargo check` sau mỗi thay đổi
5. **Báo cáo tóm tắt**: Cho biết đã sửa gì và còn lại gì

## Khi nào dùng

Dùng `/rust-build` khi:
- `cargo build` hoặc `cargo check` thất bại với lỗi
- `cargo clippy` báo cảnh báo
- Lỗi borrow checker hoặc lifetime chặn việc compile
- Việc resolve dependency của Cargo thất bại
- Sau khi pull các thay đổi làm hỏng build

## Các lệnh chẩn đoán được chạy

```bash
# Primary build check
cargo check 2>&1

# Lints and suggestions
cargo clippy -- -D warnings 2>&1

# Formatting check
cargo fmt --check 2>&1

# Dependency issues
cargo tree --duplicates

# Security audit (if available)
if command -v cargo-audit >/dev/null; then cargo audit; else echo "cargo-audit not installed"; fi
```

## Ví dụ phiên làm việc

````text
User: /rust-build

Agent:
# Rust Build Resolution

## Initial Diagnostics

```bash
$ cargo check
error[E0502]: cannot borrow `map` as mutable because it is also borrowed as immutable
  --> src/service/cache.rs:25:5
error[E0308]: mismatched types
  --> src/handler/api.rs:42:12
error[E0425]: cannot find value `db` in this scope
  --> src/handler/api.rs:58:9
```

Errors found: 3

## Fix 1: Borrow Checker Error

File: src/service/cache.rs:25
Error: E0502 — cannot borrow `map` as mutable because also borrowed as immutable
Cause: Immutable borrow still active during mutable insert

```rust
// Changed: restructured to end immutable borrow before mutable access
if !map.contains_key("key") {
    map.insert("key".into(), default);
}
```

```bash
$ cargo check
# 2 errors remaining
```

## Fix 2: Type Mismatch

File: src/handler/api.rs:42
Error: E0308 — mismatched types: expected `usize`, found `&str`

```rust
// Changed
let count = params.get("count");
// To
let count: usize = params.get("count")
    .and_then(|s| s.parse().ok())
    .unwrap_or(0);
```

```bash
$ cargo check
# 1 error remaining
```

## Fix 3: Unresolved Name

File: src/handler/api.rs:58
Error: E0425 — cannot find value `db` in this scope
Cause: Missing import

```rust
// Added
use crate::db;
```

```bash
$ cargo check
# Build successful!
```

## Final Verification

```bash
$ cargo clippy -- -D warnings
# No warnings

$ cargo test
running 6 tests
test service::cache::tests::test_insert ... ok
test service::cache::tests::test_get ... ok
test handler::api::tests::test_parse_count ... ok
test handler::api::tests::test_missing_count ... ok
test handler::api::tests::test_db_import ... ok
test handler::api::tests::test_response ... ok

test result: ok. 6 passed; 0 failed; 0 ignored
```

## Summary

| Metric | Count |
|--------|-------|
| Build errors fixed | 3 |
| Clippy warnings fixed | 0 |
| Files modified | 2 |
| Remaining issues | 0 |

Build Status: SUCCESS
````

## Các lỗi thường gặp đã sửa

| Lỗi | Cách sửa điển hình |
|-------|-------------|
| `cannot borrow as mutable` | Cấu trúc lại để kết thúc immutable borrow trước; chỉ clone khi có lý do chính đáng |
| `does not live long enough` | Dùng owned type hoặc thêm lifetime annotation |
| `cannot move out of` | Cấu trúc lại để lấy ownership; clone chỉ là phương án cuối cùng |
| `mismatched types` | Thêm `.into()`, `as` hoặc chuyển đổi tường minh |
| `trait X not implemented` | Thêm `#[derive(Trait)]` hoặc tự implement |
| `unresolved import` | Thêm vào Cargo.toml hoặc sửa đường dẫn `use` |
| `cannot find value` | Thêm import hoặc sửa đường dẫn |

## Chiến lược sửa

1. **Lỗi build trước** - Code phải compile được
2. **Cảnh báo Clippy thứ hai** - Sửa các cấu trúc đáng ngờ
3. **Định dạng thứ ba** - tuân thủ `cargo fmt`
4. **Mỗi lần một bản sửa** - Xác minh từng thay đổi
5. **Thay đổi tối thiểu** - Không refactor, chỉ sửa

## Điều kiện dừng

Agent sẽ dừng và báo cáo nếu:
- Cùng một lỗi vẫn tồn tại sau 3 lần thử
- Bản sửa gây ra thêm lỗi
- Cần thay đổi kiến trúc
- Lỗi borrow checker đòi hỏi thiết kế lại ownership của dữ liệu

## Các lệnh liên quan

- `/rust-test` - Chạy test sau khi build thành công
- `/rust-review` - Review chất lượng code
- skill `verification-loop` - Vòng lặp verification đầy đủ

## Liên quan

- Agent: `agents/rust-build-resolver.md`
- Skill: `skills/rust-patterns/`
