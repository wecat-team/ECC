---
description: Code review Rust toàn diện về ownership, lifetime, xử lý lỗi, việc dùng unsafe và các pattern idiomatic. Gọi agent rust-reviewer.
---

# Rust Code Review

Lệnh này gọi agent **rust-reviewer** để thực hiện code review toàn diện dành riêng cho Rust.

## Lệnh này làm gì

1. **Xác minh các kiểm tra tự động**: Chạy `cargo check`, `cargo clippy -- -D warnings`, `cargo fmt --check` và `cargo test` — dừng nếu bất kỳ cái nào thất bại
2. **Xác định thay đổi Rust**: Tìm các file `.rs` đã sửa qua `git diff HEAD~1` (hoặc `git diff main...HEAD` cho PR)
3. **Chạy audit bảo mật**: Thực thi `cargo audit` nếu có
4. **Quét bảo mật**: Kiểm tra việc dùng unsafe, command injection, secret hardcode
5. **Review ownership**: Phân tích clone không cần thiết, vấn đề lifetime, pattern borrow
6. **Tạo báo cáo**: Phân loại vấn đề theo mức độ nghiêm trọng

## Khi nào dùng

Dùng `/rust-review` khi:
- Sau khi viết hoặc sửa code Rust
- Trước khi commit các thay đổi Rust
- Review pull request có code Rust
- Làm quen với một codebase Rust mới
- Học các pattern Rust idiomatic

## Các nhóm review

### CRITICAL (Phải sửa)
- `unwrap()`/`expect()` không kiểm tra trong các đường code production
- `unsafe` không có comment `// SAFETY:` ghi lại các invariant
- SQL injection qua nội suy chuỗi trong query
- Command injection qua đầu vào chưa kiểm tra trong `std::process::Command`
- Credential hardcode
- Use-after-free qua raw pointer

### HIGH (Nên sửa)
- `.clone()` không cần thiết chỉ để thỏa borrow checker
- Tham số `String` trong khi `&str` hoặc `impl AsRef<str>` là đủ
- Blocking trong ngữ cảnh async (`std::thread::sleep`, `std::fs`)
- Thiếu ràng buộc `Send`/`Sync` trên các type dùng chung
- Match wildcard `_ =>` trên các enum quan trọng với nghiệp vụ
- Function lớn (>50 dòng)

### MEDIUM (Cân nhắc)
- Cấp phát không cần thiết trong hot path
- Thiếu `with_capacity` khi đã biết kích thước
- Tắt cảnh báo clippy mà không có lý do
- API public không có tài liệu `///`
- Cân nhắc `#[must_use]` trên các return type chưa có `must_use` mà việc bỏ qua giá trị có khả năng là bug

## Các kiểm tra tự động được chạy

```bash
# Build gate (must pass before review)
cargo check

# Lints and suggestions
cargo clippy -- -D warnings

# Formatting
cargo fmt --check

# Tests
cargo test

# Security audit (if available)
if command -v cargo-audit >/dev/null; then cargo audit; else echo "cargo-audit not installed"; fi
```

## Ví dụ sử dụng

````text
User: /rust-review

Agent:
# Rust Code Review Report

## Files Reviewed
- src/service/user.rs (modified)
- src/handler/api.rs (modified)

## Static Analysis Results
- Build: Successful
- Clippy: No warnings
- Formatting: Passed
- Tests: All passing

## Issues Found

[CRITICAL] Unchecked unwrap in Production Path
File: src/service/user.rs:28
Issue: Using `.unwrap()` on database query result
```rust
let user = db.find_by_id(id).unwrap();  // Panics on missing user
```
Fix: Propagate error with context
```rust
let user = db.find_by_id(id)
    .context("failed to fetch user")?;
```

[HIGH] Unnecessary Clone
File: src/handler/api.rs:45
Issue: Cloning String to satisfy borrow checker
```rust
let name = user.name.clone();
process(&user, &name);
```
Fix: Restructure to avoid clone
```rust
let result = process_name(&user.name);
use_user(&user, result);
```

## Summary
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 0

Recommendation: Block merge until CRITICAL issue is fixed
````

## Tiêu chí phê duyệt

| Trạng thái | Điều kiện |
|--------|-----------|
| Approve | Không có vấn đề CRITICAL hoặc HIGH |
| Warning | Chỉ có vấn đề MEDIUM (merge cần thận trọng) |
| Block | Phát hiện vấn đề CRITICAL hoặc HIGH |

## Tích hợp với các lệnh khác

- Dùng `/rust-test` trước để đảm bảo test pass
- Dùng `/rust-build` nếu xảy ra lỗi build
- Dùng `/rust-review` trước khi commit
- Dùng `/code-review` cho các mối quan tâm không đặc thù Rust

## Liên quan

- Agent: `agents/rust-reviewer.md`
- Skills: `skills/rust-patterns/`, `skills/rust-testing/`
